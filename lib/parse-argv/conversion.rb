# frozen_string_literal: true

require 'set'

module ParseArgv
  #
  # The Conversion module provides an interface to convert String arguments to
  # different types and is used by the {Result::Value#as} method.
  #
  # Besides the build-in defined types custom conversion functions can be
  # defined with {Conversion.define}.
  #
  # In general a conversion function is a Proc which gets called with a String
  # argument, an error handler and - optional - with function-specific
  # arguments and options.
  #
  # The conversion function should convert the given String argument and return
  # the result. When it's impossible to convert the argument the error handler
  # have to be called with a descriptive error message.
  #
  # Here is an example for a conversion function of even Integer:
  #
  # ```
  # ParseArgv::Conversion.define(:even_number) do |arg, &err|
  #   /\A-?\d+/.match?(arg) or err['argument have to be an even integer']
  #   result = arg.to_i
  #   result.even? ? result : err['not an even integer']
  # end
  # ```
  #
  # ## Build-In Conversion Functions
  #
  # <table>
  # <thead><th>Name</th><th>Alias</th><th>Description</th></thead>
  # <tbody>
  #   <tr>
  #     <td>:integer</td><td>Integer</td>
  #     <td>
  #       convert to <code>Integer</code>; it allows additional checks like
  #       :positive, :negative, :nonzero
  #      </td>
  #   </tr>
  #   <tr>
  #     <td>:float</td><td>Float</td>
  #     <td>
  #       convert to <code>Float</code>; it allows additional checks like
  #       :positive, :negative, :nonzero
  #     </td>
  #   </tr>
  #   <tr>
  #     <td>:number</td><td>Numeric</td>
  #     <td>
  #       convert to <code>Float</code> or <code>Integer</code>; it
  #       allows additional checks like :positive, :negative, :nonzero
  #     </td>
  #   </tr>
  #   <tr>
  #     <td>:byte</td><td></td>
  #     <td>
  #       convert to <code>Integer</code>; argument can have suffix
  #       <code>k</code>ilo, <code>M</code>ega, <code>G</code>iga,
  #       <code>T</code>era, <code>P</code>eta, <code>E</code>xa,
  #       <code>Z</code>etta and <code>Y</code>otta ('0.5M' == 524288)
  #     </td>
  #   </tr>
  #   <tr>
  #     <td>:string</td><td>String</td>
  #     <td>passes a non-empty string argument</td>
  #   </tr>
  #   <tr>
  #     <td>:file_name</td><td></td>
  #     <td>convert to file name; uses <code>File#expand_path</code></td>
  #   </tr>
  #   <tr>
  #     <td>:regexp</td><td>Regexp</td>
  #     <td>convert to a <code>Regexp</code></td>
  #   </tr>
  #   <tr>
  #     <td>:array</td><td>Array</td>
  #     <td>convert to a <code>Array&lt;String&gt;</code></td>
  #   </tr>
  #   <tr>
  #     <td>:date</td><td>Date</td>
  #     <td>
  #       convert to a <code>Date</code>; accepts optional a <code>Date</code>
  #       or <code>Time</code> as :reference option
  #     </td>
  #   </tr>
  #   <tr>
  #     <td>:time</td><td>Time</td>
  #     <td>
  #       convert to a <code>Time</code>>; accepts optional a <code>Date</code>
  #       or <code>Time</code> as :reference option
  #     </td>
  #   </tr>
  #   <tr>
  #     <td>:file</td><td>File</td>
  #     <td>
  #       convert to a file name; checks if the file exists; allows additional
  #       checks like :blockdev, :chardev, :grpowned, :owned, :readable,
  #       :readable_real, :setgid, :setuid, :size, :socket, :sticky, :symlink
  #       :world_readable, :world_writeable, :writable, :writable_real, :zero
  #    </td>
  #   </tr>
  #   <tr>
  #     <td>:directory</td><td>Dir</td>
  #     <td>
  #       convert to a directory name; checks if the directory exists; allows
  #       additional check like the :file conversion (above)
  #     </td>
  #   </tr>
  #   <tr>
  #     <td>:file_content</td><td></td>
  #     <td>
  #       expects a file name and returns the file content
  #    </td>
  #   </tr>
  # </tbody></table>
  #
  module Conversion
    class << self
      #
      # Get a conversion function.
      #
      # The requested +type+ specifies the type of returned conversion
      # function:
      #
      #   - Symbol: a defined function; see {.define}
      #   - Class: function associated to the given Class
      #   - Enumerable<String>: function to pass only given strings
      #   - Array(type): function returning converted elements of argument
      #     array
      #   - Regexp: function which passes matching arguments
      #
      # @param type [Symbol, Class, Enumerable<String>, Array(type), Regexp]
      # @return [#call] conversion function
      #
      # @example type is a Symbol
      #   ParseArgv::Conversion[:integer]
      #   # => Proc which converts an argument into an Integer
      #   ParseArgv::Conversion[:integer].call('42')
      #   # => 42
      #
      # @example type is a Class
      #   ParseArgv::Conversion[Time]
      #   # => Proc which converts an argument to a Time object
      #   ParseArgv::Conversion[Time].call('2022-01-02 12:13 CET')
      #   # => "2022-01-02 12:13:00 +0100"
      #
      # @example type is a Array<String>
      #   ParseArgv::Conversion[%w[foo bar baz]]
      #   # => Proc which allows only an argument 'foo', 'bar', or 'baz'
      #   ParseArgv::Conversion[%w[foo bar baz]].call('bar')
      #   # => "bar"
      #
      # @example type is a Array(type)
      #   ParseArgv::Conversion[[:number]]
      #   # => Proc which converts an argument array to numbers
      #   ParseArgv::Conversion[[:number]].call('42, 21.84')
      #   # => [42, 21.84]
      #
      # @example type is a Regexp
      #   Conversion[/\Ate+st\z/]
      #   # => Proc which allows only an argument matching the Regexp
      #   Conversion[/\Ate+st\z/].call('teeeeeeest')
      #   # => "teeeeeeest"
      #
      def [](type)
        return regexp_match(type) if type.is_a?(Regexp)
        if type.is_a?(Array) && type.size == 1
          return array_of(Conversion[type.first])
        end
        return enum_type(type) if type.is_a?(Enumerable)
        (@ll[type] || @ll[type.to_sym]) or
          raise(UnknownAttributeConverterError, type)
      end

      #
      # Define a conversion function or an alias between two conversion
      # functions.
      #
      # @overload define(name, &block)
      #   Define the conversion function for specified +name+.
      #   @param name [Symbol] conversion function name
      #   @param block [Proc] conversion function
      #
      #   @example define the type +:odd_number+
      #     ParseArgv::Conversion.define(:odd_number) do |arg, &err|
      #       result = ParseArgv::Conversion[:number].call(arg, &err)
      #       result.odd? ? result : err['argument must be an odd number']
      #     end
      #
      # @overload define(new_name, old_name)
      #   Creates an alias between two conversion functions.
      #   @param new_name [Symbol] new name for the handler
      #   @param old_name [Symbol] name of existing handler
      #
      #   @example define the alias +:odd+ for the existing type +:odd_number+
      #     ParseArgv::Conversion.define(:odd, :odd_number)
      #
      # @return [Conversion] itself
      #
      def define(name, old_name = nil, &block)
        @ll[name] = old_name.nil? ? block : self[old_name]
        self
      end

      private

      def regexp_match(regexp)
        proc do |arg, *args, &err|
          if args.include?(:match)
            match = regexp.match(arg) and next match
          else
            regexp.match?(arg) and next arg
          end
          err["argument must match #{regexp}"]
        end
      end

      def enum_type(enum)
        set = Set.new(enum) { |e| e.to_s.strip }
        proc do |arg, &err|
          next arg if set.include?(arg)
          allowed = set.map { |s| "`#{s}`" }.join(', ')
          err["argument must be one of [#{allowed}]"]
        end
      end

      def array_of(type)
        proc do |arg, *args, **opts, &err|
          Conversion[:array]
            .call(arg, &err)
            .map! { |a| type.call(a, *args, **opts, &err) }
        end
      end
    end

    @ll = {}

    define(:integer) do |arg, type = nil, &err|
      /\A-?\d+/.match?(arg) or err['argument must be an integer']
      arg = arg.to_i
      case type
      when :positive
        arg.positive? or err['argument must be a positive integer']
      when :negative
        arg.negative? or err['argument must be a negative integer']
      when :nonzero
        arg.nonzero? or err['argument must be a nonzero integer']
      end
      arg
    end
    define(Integer, :integer)

    define(:float) do |arg, type = nil, &err|
      /\A[+\-]?\d*\.?\d+(?:[Ee][+\-]?\d+)?/.match?(arg) or
        err['argument must be a float number']
      arg = arg.to_f
      case type
      when :positive
        arg.positive? or err['argument must be a positive float number']
      when :negative
        arg.negative? or err['argument must be a negative float number']
      when :nonzero
        arg.nonzero? or err['argument must be a nonzero float number']
      end
      arg
    end
    define(Float, :float)

    define(:number) do |arg, type = nil, &err|
      /\A[\+\-]?\d*\.?\d+(?:[Ee][\+\-]?\d+)?/.match?(arg) or
        err['argument must be a number']
      arg = arg.to_f
      argi = arg.to_i
      arg = argi if argi == arg
      case type
      when :positive
        arg.positive? or err['argument must be a positive number']
      when :negative
        arg.negative? or err['argument must be a negative number']
      when :nonzero
        arg.nonzero? or err['argument must be a nonzero number']
      end
      arg
    end
    define(Numeric, :number)

    define(:byte) do |arg, base: 1024, &err|
      match = /\A(\d*\.?\d+(?:[Ee][\+\-]?\d+)?)([kmgtpezyKMGTPEZY]?)/.match(arg)
      match or err['argument must be a byte number']
      (match[1].to_f * (base**' kmgtpezy'.index(match[2].downcase))).to_i
    end

    define(:string) do |arg, &err|
      arg.empty? ? err['argument must be not empty'] : arg
    end
    define(String, :string)

    define(:file_name) do |arg, rel: nil, &err|
      File.expand_path(Conversion[:string].call(arg, &err), rel)
    end

    define(:regexp) do |arg, &err|
      Regexp.new(
        Conversion[:string].call(
          arg.delete_prefix('/').delete_suffix('/'),
          &err
        )
      )
    rescue RegexpError => e
      err["invalid regular expression; #{e}"]
    end
    define(Regexp, :regexp)

    define(:array) do |arg, &err|
      arg = arg[1..-2] if arg[0] == '[' && arg[-1] == ']'
      arg = arg.split(',').map!(&:strip)
      arg.uniq!
      arg.delete('')
      arg.empty? ? err['argument can not be empty'] : arg
    end
    define(Array, :array)

    define(:date) do |arg, reference: nil, &err|
      defined?(::Date) or require('date')
      ret = Date._parse(arg)
      err['argument must be a date'] if ret.empty?
      reference ||= Date.today
      Date.new(
        ret[:year] || reference.year,
        ret[:mon] || reference.mon,
        ret[:mday] || reference.mday
      )
    rescue Date::Error
      err['argument must be a date']
    end
    defined?(::Date) && define(Date, :date)

    define(:time) do |arg, reference: nil, &err|
      defined?(::Date) or require('date')
      ret = Date._parse(arg)
      err['argument must be a time'] if ret.empty?
      reference ||= Date.today
      Time.new(
        ret[:year] || reference.year,
        ret[:mon] || reference.month,
        ret[:mday] || reference.mday,
        ret[:hour] || 0,
        ret[:min] || 0,
        ret[:sec] || 0,
        ret[:offset]
      )
    rescue Date::Error
      err['argument must be a time']
    end
    define(Time, :time)

    define(:file) do |arg, *args, **opts, &err|
      fname = Conversion[:file_name].call(arg, **opts, &err)
      stat = File.stat(fname)
      stat.file? or err['argument must be a file']
      args.each do |att|
        name = "#{att}?"
        stat.respond_to?(name) or next
        stat.public_send(name) or err["file is not #{att}"]
      end
      fname
    rescue Errno::ENOENT
      err['file does not exist']
    end
    define(File, :file)

    define(:file_content) do |arg, **opts, &err|
      next $stdin.read if arg == '-'
      fname = Conversion[:file].call(arg, :readable, **opts, &err)
      File.read(fname)
    rescue SystemCallError
      err['file is not readable']
    end

    define(:directory) do |arg, *args, **opts, &err|
      fname = Conversion[:file_name].call(arg, **opts, &err)
      stat = File.stat(fname)
      stat.directory? or err['argument must be a directory']
      args.each do |att|
        name = "#{att}?"
        stat.respond_to?(name) or next
        stat.public_send(name) or err["directory is not #{att}"]
      end
      fname
    rescue Errno::ENOENT
      err['directory does not exist']
    end
    define(Dir, :directory)
  end
end
