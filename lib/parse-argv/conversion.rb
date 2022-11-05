# frozen_string_literal: true

module ParseArgv
  module Conversion
    class << self
      #
      # Get a conversion procedure.
      #
      # The requested +type+ specifies the type of returned conversion
      # procedure:
      #
      #   - Symbol: a defined procedure; see {.define}
      #   - Class: procedure associated to the given Class
      #   - Array<String>: procedure to pass only given strings
      #   - Array(type): procedure returning converted elements of argument
      #     array
      #   - Regexp: procedure which passes matching arguments
      #
      # @param type [Symbol, Class, Array<String>, Array(type), Regexp]
      # @return [#call] conversion procedure
      #
      # @example type is a Symbol
      #   ParseArgv::Conversion[:downcase]
      #   # => Proc which converts an argument to lower case
      #   ParseArgv::Conversion[:downcase].call('HELLo')
      #   # => "HELLO"
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
      #   ParseArgv::Conversion[[:positive]]
      #   # => Proc which converts an argument array to positive Integers
      #   ParseArgv::Conversion[[:positive]].call('[42, 21]')
      #   # => [42, 21]
      #
      # @example type is a Regexp
      #   Conversion[/\Ate+st\z/]
      #   # => Proc which allows only an argument matching the Regexp
      #   Conversion[/\Ate+st\z/].call('teeeeeeest')
      #   # => "teeeeeeest"
      #
      def [](type)
        @ll.fetch(type) do
          next regexp_match(type) if type.is_a?(Regexp)
          next array_type(type) if type.is_a?(Array)
          @ll.fetch(type.to_sym) { raise(UnknownAttributeConverterError, type) }
        end
      end

      #
      # @overload define(name, &block)
      #   Define the conversion procedure for specified +name+.
      #   @param name [Symbol] conversion procedure name
      #   @param block [Proc] conversion procedure
      #
      #   @example define the type +:odd_number+
      #     ParseArgv::Conversion.define(:odd_number) do |arg, &err|
      #       result = arg.to_i
      #       result.odd? ? result : err['not an odd number']
      #     end
      #
      # @overload define(new_name, old_name)
      #   Creates an alias between two conversion procedures.
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

      def one_of(ary)
        proc do |arg, *opts, &err|
          next arg if ary.include?(arg)
          err["argument must be one of #{ary.map { |s| "`#{s}`" }.join(', ')}"]
        end
      end

      def regexp_match(regexp)
        proc do |arg, *args, &err|
          if args.include?(:match)
            match = regexp.match(arg) and next match
          else
            next arg if regexp.match?(arg)
          end
          err["argument must match #{regexp}"]
        end
      end

      def array_type(ary)
        return one_of(ary.map(&:to_s).map!(&:strip)) if ary.size != 1
        array_of(Conversion[ary.first])
      end

      def array_of(type)
        proc do |arg, *args, **opts, &err|
          Conversion[:array]
            .call(arg, &err)
            .map! { |a| type.call(a, *args, **opts, &err) }
        end
      end
    end

    @ll = { integer: proc { |arg| arg.to_i }, float: proc { |arg| arg.to_f } }

    define(:int, :integer)
    define(Integer, :integer)
    define(Float, :float)

    define(:string) do |arg, &err|
      arg.empty? ? err['argument can not be empty'] : arg
    end
    define(:str, :string)
    define(String, :string)

    define(:upcase) do |arg, &err|
      arg.empty? ? err['argument can not be empty'] : arg.upcase
    end

    define(:downcase) do |arg, &err|
      arg.empty? ? err['argument can not be empty'] : arg.downcase
    end

    define(:capitalze) do |arg, &err|
      arg.empty? ? err['argument can not be empty'] : arg.capitalze
    end

    define(:file_name) do |arg, &err|
      File.expand_path(Conversion[:string].call(arg, &err))
    end

    define(:positive) do |arg, &err|
      arg = arg.to_i
      arg.positive? ? arg : err['positive number expected']
    end

    define(:negative) do |arg, &err|
      arg = arg.to_i
      arg.negative? ? arg : err['negative number expected']
    end

    define(:float_positive) do |arg, &err|
      arg = arg.to_f
      arg.positive? ? arg : err['positive float number expected']
    end

    define(:float_negative) do |arg, &err|
      arg = arg.to_f
      arg.negative? ? arg : err['negative float number expected']
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
    define(:regex, :regexp)
    define(Regexp, :regexp)

    define(:array) do |arg, &err|
      arg = arg[1..-2] if arg.start_with?('[') && arg.end_with?(']')
      arg = arg.split(',').map!(&:strip)
      arg.uniq!
      arg.delete('')
      arg.empty? ? err['argument can not be empty'] : arg
    end
    define(Array, :array)

    define(:date) do |arg, reference: nil, &err|
      defined?(::Date) || require('date')
      ret = Date._parse(arg)
      err['argument must be a date'] if ret.empty?
      ref = reference || Date.today
      Date.new(
        ret[:year] || ref.year,
        ret[:mon] || ref.mon,
        ret[:mday] || ref.mday
      )
    rescue Date::Error
      err['argument must be a date']
    end
    defined?(::Date) && define(Date, :date)

    define(:time) do |arg, reference: nil, &err|
      defined?(::Date) || require('date')
      ret = Date._parse(arg)
      err['argument must be a time'] if ret.empty?
      ref = reference || Date.today
      Time.new(
        ret[:year] || ref.year,
        ret[:mon] || ref.month,
        ret[:mday] || ref.mday,
        ret[:hour] || 0,
        ret[:min] || 0,
        ret[:sec] || 0,
        ret[:offset]
      )
    rescue Date::Error
      err['argument must be a time']
    end
    define(Time, :time)

    define(:file) do |arg, *args, &err|
      fname = Conversion[:file_name].call(arg, &err)
      stat = File.stat(fname)
      err['argument must be a file'] unless stat.file?
      args.each do |arg|
        name = "#{arg}?"
        next unless stat.respond_to?(name)
        next if stat.send(name)
        err["file attribute `#{arg}` not satisfied"]
      end
      fname
    rescue Errno::ENOENT
      err['file does not exist']
    end
    define(File, :file)

    define(:directory) do |arg, *args, &err|
      fname = Conversion[:file_name].call(arg, &err)
      stat = File.stat(fname)
      err['argument must be a directory'] unless stat.directory?
      args.each do |arg|
        name = "#{arg}?"
        next unless stat.respond_to?(name)
        next if stat.send(name)
        err["directory attribute `#{arg}` not satisfied"]
      end
      fname
    rescue Errno::ENOENT
      err['directory does not exist']
    end
    define(:dir, :directory)
    define(Dir, :directory)
  end
end
