# frozen_string_literal: true

module ParseArgv
  module Conversion
    class << self
      def for(type)
        @ll.fetch(type) do
          next one_of(as_string_array(type)) if type.is_a?(Array)
          next regexp_match(type) if type.is_a?(Regexp)
          ary_type = array_type(type) and next array_of(ary_type)
          raise(UnknownAttributeConverter, type)
        end
      end

      def define(type, existing_type = nil, &block)
        @ll[type] = existing_type.nil? ? block : self.for(existing_type)
        self
      end

      private

      def as_string_array(type)
        type.map(&:to_s).map!(&:strip)
      end

      def one_of(ary)
        proc do |arg, &err|
          next arg if ary.include?(arg)
          err["argument must be one of #{ary.map { |s| "`#{s}`" }.join(', ')}"]
        end
      end

      def regexp_match(regexp)
        proc do |arg, &err|
          regexp.match?(arg) ? arg : err["argument must match #{regexp}"]
        end
      end

      def array_type(str)
        return unless str.is_a?(String)
        return unless str.start_with?('array[') && str.end_with?(']')
        type = str.delete_prefix('array[').delete_suffix(']')
        Conversion.for(type.empty? ? :array : type.to_sym)
      end

      def array_of(type)
        proc do |arg, &err|
          Conversion.for(:array).call(arg, &err).map! { |a| type.call(a, &err) }
        end
      end
    end

    @ll = { integer: ->(arg) { arg.to_i }, float: ->(arg) { arg.to_f } }
    define(:int, :integer)
    define(Integer, :integer)
    define(Float, :float)

    define(:string) do |arg, &err|
      arg.empty? ? err['argument can not be empty'] : arg
    end
    define(:str, :string)
    define(String, :string)

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

    define(:file) do |arg, *opts, &err|
      fname = Conversion.for(:file_name).call(arg, &err)
      stat = File.stat(fname)
      err['argument must be a file'] unless stat.file?
      opts.each do |opt|
        name = "#{opt}?"
        next unless stat.respond_to?(name)
        next if stat.send(name)
        err["file attribute `#{opt}` not satisfied"]
      end
      fname
    rescue Errno::ENOENT
      err['file does not exist']
    end
    define(File, :file)

    define(:directory) do |arg, *opts, &err|
      fname = Conversion.for(:file_name).call(arg, &err)
      stat = File.stat(fname)
      err['argument must be a directory'] unless stat.directory?
      opts.each do |opt|
        name = "#{opt}?"
        next unless stat.respond_to?(name)
        next if stat.send(name)
        err["directory attribute `#{opt}` not satisfied"]
      end
      fname
    rescue Errno::ENOENT
      err['directory does not exist']
    end
    define(:dir, :directory)
    define(Dir, :directory)
  end
end
