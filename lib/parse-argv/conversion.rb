# frozen_string_literal: true

module ParseArgv
  module Conversion
    class << self
      #
      # Requests for a conversion procedure.
      #
      # @overload for(type)
      #   @param type [Symbol, Class] name or class of the conversion procedure
      #   @raise [ArgumentError] when no conversion procedure was defined
      #   @example
      #     ParseArgv::Conversion.for(:file)
      #     ParseArgv::Conversion.for(File)
      #
      # @overload for(array)
      #   @param array [Array<String>] conversion procedure checking if an
      #     argument is included in +array+.
      #   @example
      #     ParseArgv::Conversion.for(%w[foo bar baz])
      #
      # @overload for(type_array)
      #   @param type_array [Array] Array with one type element
      #   @example
      #     ParseArgv::Conversion.for([:integer])
      #     ParseArgv::Conversion.for([Integer])
      #
      # @overload for(regexp)
      #   @param regexp [Regexp] conversion procedure checking if an argument
      #     matches the regular expression
      #   @example
      #     ParseArgv::Conversion.for(/\A\w+_test\z/)
      #
      # @return [#call] conversion procedure
      #
      def for(type)
        @ll.fetch(type) do
          next regexp_match(type) if type.is_a?(Regexp)
          next array_type(type) if type.is_a?(Array)
          @ll.fetch(type.to_sym) { raise(UnknownAttributeConverter, type) }
        end
      end

      #
      # Define the conversion procedure for specified +name+.
      #
      # @overload define(name, &block)
      #   @param name [Symbol] conversion procedure name
      #   @param block [Proc] conversion procedure
      #   @example define the type +:odd_number+
      #     ParseArgv::Conversion.define(:odd_number) do |arg, &err|
      #       result = arg.to_i
      #       result.odd? || err['not an odd number']
      #       result
      #     end
      #
      # @overload define(new_name, old_name)
      #   Creates an alias between two conversion procedures.
      #   @param new_name [Symbol] new name for the handler
      #   @param old_name [Symbol] name of existing handler
      #   @example define the alias +:odd+ for the existing type +:odd_number+
      #     ParseArgv::Conversion.define(:odd, :odd_number)
      #
      # @return [Conversion] itself
      #
      def define(name, old_name = nil, &block)
        @ll[name] = old_name.nil? ? block : self.for(old_name)
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
        array_of(Conversion.for(ary.first))
      end

      def array_of(type)
        proc do |arg, *args, **opts, &err|
          Conversion
            .for(:array)
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
      File.expand_path(Conversion.for(:string).call(arg, &err))
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
        Conversion.for(:string).call(
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

    define(:date) do |arg, &err|
      require('date') unless defined?(::Date)
      ret = Date._parse(arg)
      err['argument must be a date'] if ret.empty?
      ref = Date.today
      Date.new(
        ret[:year] || ref.year,
        ret[:mon] || ref.mon,
        ret[:mday] || ref.mday
      )
    rescue Date::Error
      err['argument must be a date']
    end

    define(:time) do |arg, &err|
      require('date') unless defined?(::Date)
      ret = Date._parse(arg)
      err['argument must be a time'] if ret.empty?
      ref = Date.today
      Time.new(
        ret[:year] || ref.year,
        ret[:mon] || ref.month,
        ret[:mday] || ref.mday,
        ret[:hour] || 0,
        ret[:min] || 0,
        ret[:sec] || 0,
        ret[:offset]
      )
    end

    define(:file) do |arg, *args, &err|
      fname = Conversion.for(:file_name).call(arg, &err)
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
      fname = Conversion.for(:file_name).call(arg, &err)
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
