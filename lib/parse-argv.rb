# frozen_string_literal: true

#
# ParseArgv uses a help text of a command line interface (CLI) to find out how
# to parse a command line. It takes care that required command line arguments
# are given and optional arguments are consumed.
#
# With a given help text and a command line it produces a {Result} which
# contains all values and meta data ({ParseArgv.from}). The {Result::Value}s
# support type {Conversion} and contextual error handling ({Result::Value#as}).
#
# For some debugging and test purpose it can also serialize a given help text
# to a informational format ({ParseArgv.parse}).
#
# For details about the help text syntax see {file:syntax.md}.
#
# @example
#   require 'parse-argv'
#
#   args = ParseArgv.from <<~HELP
#     usage: test [options] <infile> [<outfile>]
#
#     This is just a demonstration.
#
#     options:
#       -f, --format <format>   specify the format
#       --verbose               enable verbose mode
#       -h, --help              print this help text
#   HELP
#
#   args.verbose?
#   #=> true, when "--verbose" argument was specified
#   #=> false, when "--verbose" argument was not specified
#
#   args[:infile].as(File, :readable)
#   #=> file name
#
#   args.outfile?
#   #=> true, when second argument was specified
#   args.outfile
#   #=> second argument or nil when not specified
#
module ParseArgv
  #
  # Parses the given +help_text+ and command line +argv+ to create an {Result}.
  #
  # @param help_text [String] help text describing all sub-commands, parameters
  #   and options in human readable format
  # @param argv [Array<String>] command line arguments
  # @return [Result] the arguments parsed from +argv+ related to the given
  #   +help_text+.
  #
  def self.from(help_text, argv = ARGV)
    result = Result.new(*Assemble[help_text, argv])
    block_given? ? yield(result) : result
  rescue Error => e
    @on_error&.call(e) or raise
  end

  #
  # Parses the given +help_text+ and returns descriptive information about the
  # commands found.
  #
  # This method can be used to test a +help_text+.
  #
  # @param help_text [String] help text describing all sub-commands, parameters
  #   and options in human readable format
  # @return [Array<Hash>] descriptive information
  # @raise [ArgumentError] when the help text contains invalid information
  #
  def self.parse(help_text)
    Assemble.commands(help_text).map!(&:to_h)
  end

  #
  # Defines custom error handler which will be called with the detected
  # {Error}.
  #
  # By default the error handler writes the {Error#message} prefixed with
  # related {Error#command} name to *$std_err* and terminates the application
  # with the suggested {Error#code}.
  #
  # @overload on_error(function)
  #   Uses the given call back function to handle all parsing errors.
  #   @param func [Proc] call back function which receives the {Error}
  #   @example
  #     ParseArgv.on_error ->(e) { $stderr.puts e or exit e.code }
  #
  # @overload on_error(&block)
  #   Uses the given +block+ to handle all parsing errors.
  #   @example
  #     ParseArgv.on_error do |e|
  #       $stderr.puts(e)
  #       exit(e.code)
  #     end
  #
  # @return [ParseArgv] itself
  #
  def self.on_error(function = nil, &block)
    function ||= block or return @on_error
    @on_error = function == :raise ? nil : function
    self
  end

  #
  # Raised when the command line is parsed and an error was found.
  #
  # @see .on_error
  #
  class Error < StandardError
    #
    # @return [Integer] error code
    #
    attr_reader :code
    #
    # @return [Result::Command] related command
    #
    attr_reader :command

    #
    # @!attribute [r] message
    # @return [String] message to be reported
    #

    #
    # @param command [Result::Command] related command
    # @param message [String] message to be reported
    # @param code [Integer] error code
    #
    def initialize(command, message, code = 1)
      @command = command
      @code = code
      super("#{command.full_name}: #{message}")
    end
  end

  #
  # The result of a complete parsing process made with {ParseArgv.from}. It
  # contains all arguments parsed from the command line and the defined
  # commands.
  #
  class Result
    #
    # Represents a command with a name and related help text
    #
    class Command
      #
      # @return [String] complete command name
      #
      attr_reader :full_name
      #
      # @return [String] subcommand name
      #
      attr_reader :name

      # @!visibility private
      def initialize(full_name, help, name = nil)
        @full_name = full_name.freeze
        @help = help
        @name = name || +@full_name
      end

      # @!parse attr_reader :help
      # @return [String] help text of the command
      def help
        return @help if @help.is_a?(String)
        @help.shift while @help[0]&.empty?
        @help.pop while @help[-1]&.empty?
        @help = @help.join("\n").freeze
      end

      # @!visibility private
      def inspect
        "#{__to_s[..-2]} #{@full_name}>"
      end

      alias __to_s to_s
      private :__to_s
      alias to_s name
    end

    #
    # This is a helper class to get parsed arguments from {Result} to be
    # converted.
    #
    # @see Result#[]
    #
    class Value
      include Comparable

      #
      # @return [Object] the argument value
      #
      attr_reader :value

      # @!visibility private
      def initialize(value, error_proc)
        @value = value
        @error_proc = error_proc
      end

      #
      # @attribute [r] value?
      # @return [Boolean] whenever the value is nil and not false
      #
      def value?
        @value != nil && @value != false
      end

      #
      # Requests the value to be converted to a specified +type+. It uses
      # {Conversion.[]} to obtain the conversion procedure.
      #
      # Some conversion procedures allow additional parameters which will be
      # forwarded.
      #
      # @example convert to a positive number (or fallback to 10)
      #   sample.as(:integer, :positive, default: 10)
      #
      # @example convert to a file name of an existing, readable file
      #   sample.as(File, :readable)
      #
      # @example convert to Time and use the +reference+ to complete  the the date parts (when not given)
      #   sample.as(Time, reference: Date.new(2022, 1, 2))
      #
      # @param type [Symbol, Class, Enumerable<String>, Array(type), Regexp]
      #   conversion type, see {Conversion.[]}
      # @param args [Array<Object>] optional arguments to be forwarded to the
      #   conversion procedure
      # @param default [Object] returned, when an argument was not specified
      # @param kwargs [Symbol => Object] optional named arguments forwarded to the conversion procedure
      # @return [Object] converted argument or +default+
      #
      # @see Conversion
      #
      def as(type, *args, default: nil, **kwargs)
        return default if @value.nil?
        conv = Conversion[type]
        if value.is_a?(Array)
          return value.map { |v| conv.call(v, *args, **kwargs, &@error_proc) }
        end
        conv.call(@value, *args, **kwargs, &@error_proc)
      rescue Error => e
        ParseArgv.on_error&.call(e) or raise
      end

      # @!visibility private
      def eql?(other)
        other.is_a?(self.class) ? @value == other.value : @value == other
      end
      alias == eql?

      # @!visibility private
      def equal?(other)
        (self.class == other.class) && (@value == other.value)
      end

      # @!visibility private
      def <=>(other)
        other.is_a?(self.class) ? @value <=> other.value : @value <=> other
      end
    end

    #
    # @return [Array<Command>] all defined commands
    #
    attr_reader :all_commands

    #
    # @return [Command] command used for this result
    #
    attr_reader :current_command

    #
    # @return [Command] main command if subcommands are used
    #
    attr_reader :main_command

    # @!visibility private
    def initialize(all_commands, current_command, main_command, args)
      @all_commands = all_commands
      @current_command = current_command
      @main_command = main_command
      @rgs = args
    end

    #
    # Get an argument as {Value} which can be converted.
    #
    # @example get argument _count_ as a positive integer (or fallback to 10)
    #   result[:count].as(:integer, :positive, default: 10)
    #
    # @param name [String, Symbol] name of the requested argument
    # @return [Value] argument value
    # @return [nil] when argument is not defined
    #
    def [](name)
      name = name.to_sym
      @rgs.key?(name) ? Value.new(@rgs[name], argument_error(name)) : nil
    end

    #
    # Calls the error handler defined by {ParseArgv.on_error}.
    #
    # By default the error handler writes the {Error#message} prefixed with
    # related {Error#command} name to *$std_err* and terminates the application
    # with {Error#code}.
    #
    # If no error handler was defined an {Error} will be raised.
    #
    # This method is useful whenever your application needs signal an critical
    # error case (and should be terminated).
    #
    # @param message [String] error message to present
    # @param code [Integer] termination code
    # @raise {Error} when no error handler was defined
    #
    # @see ParseArgv.on_error
    #
    def error!(message, code = 1)
      error = Error.new(current_command, message, code)
      ParseArgv.on_error&.call(error) || raise(error)
    end

    #
    # Try to fetch the value for the given argument +name+.
    #
    # @overload fetch(name)
    #   Will raise an ArgumentError when the requested attribute does not
    #   exist.
    #   @param name [String, Symbol] attribute name
    #   @return [Object] attribute value
    #   @raise [ArgumentError] when attribute was not defined
    #
    # @overload fetch(name, default_value)
    #   Returns the +default_value+ when the requested attribute does not
    #   exist.
    #   @param name [String, Symbol] attribute name
    #   @param default_value [Object] default value to return when attribute
    #     not exists
    #   @return [Object] attribute value; maybe the +default_value+
    #
    # @overload fetch(name, &block)
    #   Returns the +block+ result when the requested attribute does not
    #   exist.
    #   @yieldparam name [Symbol] attribute name
    #   @yieldreturn [Object] return value
    #   @param name [String, Symbol] attribute name
    #   @return [Object] attribute value or result of the +block+ if attribute
    #     not found
    #
    def fetch(name, *args, &block)
      name = name.to_sym
      value = @args[name]
      return value unless value.nil?
      args.empty? ? (block || ATTRIBUTE_ERROR).call(name) : args[0]
    end

    #
    # Find the command with given +name+.
    #
    # @param name [String]
    # @return [Command] found command
    # @return [nil] when no command was found
    #
    def find_command(name)
      return if name.nil?
      name = name.is_a?(Array) ? name.join(' ') : name.to_s
      @all_commands.find { |cmd| cmd.name == name }
    end

    # @!visibility private
    def respond_to_missing?(sym, _)
      @rgs.key?(sym.end_with?('?') ? sym[..-2].to_sym : sym) || super
    end

    #
    # @overload to_h
    #   Transform itself into a Hash containing all arguments.
    #   @return [{Symbol => String, Boolean}] Hash of all argument name/value
    #     pairs
    #
    # @overload to_h(&block)
    #   @yieldparam name [Symbol] attribute name
    #   @yieldparam value [String,Boolean] attribute value
    #   @yieldreturn [Array(key, value)] key/value pair to include
    #   @return [Hash] Hash of all argument key/value pairs
    #
    def to_h(&block)
      # ensure to return a not frozen copy
      block ? @rgs.to_h(&block) : Hash[@rgs.to_a]
    end

    # @!visibility private
    def inspect
      "#{__to_s[..-2]}:#{@current_command.full_name} #{
        @rgs.map { |k, v| "#{k}: #{v}" }.join(', ')
      }>"
    end

    alias __to_s to_s
    private :__to_s

    #
    # Returns the help text of the {#current_command}
    # @return [String] the help text
    #
    def to_s
      current_command.help
    end

    private

    #
    # All command line attributes are read-only attributes for this instance.
    #
    # @example
    #   # given there was <format> option defined
    #   result.format?
    #   #=> whether the option was specified
    #   result.format
    #   # String of format option or nil, when not specified
    #
    def method_missing(sym, *args)
      args.empty? or
        raise(
          ArgumentError,
          "wrong number of arguments (given #{args.size}, expected 0)"
        )
      return @rgs.key?(sym) ? @rgs[sym] : super unless sym.end_with?('?')
      sym = sym[..-2].to_sym
      @rgs.key?(sym) or return super
      value = @rgs[sym]
      value != nil && value != false
    end

    def argument_error(name)
      proc do |message|
        raise(InvalidArgumentTypeError.new(current_command, message, name))
      end
    end

    ATTRIBUTE_ERROR = ->(name) { raise(UnknownAttributeError, name) }
    private_constant(:ATTRIBUTE_ERROR)
  end

  module Assemble
    def self.[](help_text, argv)
      Prepare.new(Commands.parse(help_text)).from(argv)
    end

    def self.commands(help_text)
      Prepare.new(Commands.parse(help_text)).all
    end

    class Prepare
      attr_reader :all

      def initialize(all_commands)
        raise(NoCommandDefinedError) if all_commands.empty?
        @all = all_commands
        @main = find_main or raise(NoDefaultCommandDefinedError)
        prepare_subcommands
      end

      def from(argv)
        @argv = Array.new(argv)
        found = @current = find_current
        (@current == @main ? all_to_cmd_main : all_to_cmd)
        @all.sort_by!(&:name).freeze
        [@all, @current, @main, found.parse(@argv)]
      end

      private

      def find_main
        @all.find { |cmd| cmd.name.index(' ').nil? }
      end

      def find_current
        @argv.empty? || @all.size == 1 ? @main : find_sub_command
      end

      def prepare_subcommands
        prefix = "#{@main.full_name} "
        @all.each do |cmd|
          next if cmd == @main
          next cmd.name.delete_prefix!(prefix) if cmd.name.start_with?(prefix)
          raise(InvalidSubcommandNameError.new(@main.name, cmd.name))
        end
      end

      def find_sub_command
        args = @argv.take_while { |arg| arg[0] != '-' }
        return @main if args.empty?
        found = find_command(args)
        found.nil? ? raise(InvalidCommandError.new(@main, args[0])) : found
      end

      def find_command(args)
        args
          .size
          .downto(1) do |i|
            name = args.take(i).join(' ')
            cmd = @all.find { |c| c != @main && c.name == name } or next
            @argv.shift(i)
            return cmd
          end
        nil
      end

      def all_to_cmd_main
        @all.map! do |command|
          next @main = @current = command.to_cmd if command == @main
          command.to_cmd
        end
      end

      def all_to_cmd
        @all.map! do |command|
          next @main = command.to_cmd if command == @main
          next @current = command.to_cmd if command == @current
          command.to_cmd
        end
      end
    end

    class Commands
      def self.parse(help_text)
        new.parse(help_text)
      end

      def initialize
        @commands = []
        @help = []
        @header_text = true
        @line_number = 0
      end

      def parse(help_text)
        help_text.each_line(chomp: true) do |line|
          @line_number += 1
          case line
          when /\A\s*#/
            @help = ['']
            next @header_text = true
          when /usage: (\w+([ \w]+)?)/i
            new_command(Regexp.last_match)
          end
          @help << line
        end
        @commands
      end

      private

      def new_command(match)
        name = match[1].rstrip
        @help = [] unless @header_text
        @header_text = false
        @commands.find do |cmd|
          next if cmd.name != name
          raise(DoublicateCommandDefinitionError.new(name, @line_number))
        end
        @command = CommandParser.new(name, @help)
        define_arguments(@command, match.post_match)
        @commands << @command
      end

      def define_arguments(parser, str)
        return if str.empty?
        str.scan(/(\[?<([[:alnum:]]+)>(\.{3})?\]?)/) do |(all, name, cons)|
          parser.argument(name.to_sym, ARGTYPE[all[0] == '['][cons.nil?])
        end
      end

      ARGTYPE = {
        true => {
          true => :optional,
          false => :optional_rest
        }.compare_by_identity,
        false => {
          true => :required,
          false => :required_rest
        }.compare_by_identity
      }.compare_by_identity
    end

    class CommandParser < Result::Command
      def initialize(name, help)
        super
        @options = {}
        @arguments = {}
        @prepared = false
      end

      def argument(name, type)
        @arguments[checked(name, DoublicateArgumentDefinitionError)] = type
      end

      def parse(argv)
        prepare! unless @prepared
        @result = {}.compare_by_identity
        arguments = parse_argv(argv)
        process_switches
        process(arguments) unless help?
        @result.freeze
      end

      def to_cmd
        Result::Command.new(@full_name, @help, @name)
      end

      def to_h
        prepare! unless @prepared
        {
          full_name: @full_name,
          name: @name.freeze,
          arguments: arguments_as_hash,
          help: help
        }
      end

      private

      def argument_type(type)
        case type
        when :optional
          { type: :argument, required: false }
        when :optional_rest
          { type: :argument_array, required: false }
        when :required
          { type: :argument, required: true }
        when :required_rest
          { type: :argument_array, required: true }
        end
      end

      def arguments_as_hash
        ret = @arguments.to_h { |n, type| [n.to_sym, argument_type(type)] }
        @options.each_pair do |name, var_name|
          tname = var_name.delete_prefix('!')
          type = var_name == tname ? :option : :switch
          tname = tname.to_sym
          next ret.dig(tname, :names) << name if ret.key?(tname)
          ret[tname] = { type: type, names: [name] }
        end
        ret.each_value { |v| v[:names]&.sort! }
      end

      def prepare!
        @help.each do |line|
          case line
          when /\A\s+-([[:alnum:]]), --([[[:alnum:]]-]+)[ :]<([[:lower:]]+)>\s+\S+/
            option(Regexp.last_match)
          when /\A\s+-{1,2}([[[:alnum:]]-]+)[ :]<([[:lower:]]+)>\s+\S+/
            simple_option(Regexp.last_match)
          when /\A\s+-([[:alnum:]]), --([[[:alnum:]]-]+)\s+\S+/
            switch(Regexp.last_match)
          when /\A\s+-{1,2}([[[:alnum:]]-]+)\s+\S+/
            simple_switch(Regexp.last_match(1))
          end
        end
        @prepared = true
        self
      end

      def help?
        name.index(' ').nil? &&
          (@result[:help] == true || @result[:version] == true)
      end

      def parse_argv(argv)
        arguments = []
        while (arg = argv.shift)
          case arg
          when '--'
            return arguments + argv
          when /\A--([[[:alnum:]]-]+)\z/
            process_option(Regexp.last_match(1), argv)
          when /\A-{1,2}([[[:alnum:]]-]+):(.+)\z/
            process_option_arg(Regexp.last_match)
          when /\A-([[:alnum:]]+)\z/
            process_opts(Regexp.last_match(1), argv)
          else
            arguments << arg
          end
        end
        arguments
      end

      def process(argv)
        reduce(argv)
        @arguments.each_pair do |key, type|
          @result[key] = case type
          when :optional
            argv.shift
          when :optional_rest
            argv.empty? ? nil : argv.shift(argv.size)
          when :required
            argv.shift or raise(ArgumentMissingError.new(self, key))
          when :required_rest
            raise(ArgumentMissingError.new(self, key)) if argv.empty?
            argv.shift(argv.size)
          end
        end
        raise(TooManyArgumentsError, self) unless argv.empty?
      end

      def argument_results(args)
        @arguments.each_key { |name| @result[name.to_sym] = args.shift }
      end

      def reduce(argv)
        keys = @arguments.keys.reverse!
        while argv.size < @arguments.size
          nonreq = keys.find { |key| @arguments[key][0] == 'o' }
          nonreq or raise(ArgumentMissingError.new(self, @arguments.keys[-1]))
          @arguments.delete(keys.delete(nonreq))
          @result[nonreq] = nil
        end
      end

      def process_option(name, argv, pref = '-')
        key = @options[name]
        raise(UnknonwOptionError.new(self, "#{pref}-#{name}")) if key.nil?
        return @result[key[1..].to_sym] = true if key[0] == '!'
        @result[key.to_sym] = value = argv.shift
        return unless value.nil? || value[0] == '-'
        raise(OptionArgumentMissingError.new(self, key, "#{pref}-#{name}"))
      end

      def process_option_arg(match)
        key = @options[match[1]] or
          raise(UnknonwOptionError.new(self, "#{match.pre_match}#{match[1]}"))
        return @result[key[1..].to_sym] = as_boolean(match[2]) if key[0] == '!'
        @result[key.to_sym] = match[2]
      end

      def process_opts(name, argv)
        name.each_char { |n| process_option(n, argv, nil) }
      end

      def process_switches
        @options.each_value do |name|
          if name[0] == '!'
            name = name[1..].to_sym
            next @result[name] = false unless @result.key?(name)
          end
          name = name.to_sym
          @result[name] = nil unless @result.key?(name)
        end
      end

      def as_boolean(str)
        %w[y yes t true on].include?(str)
      end

      def checked(name, err)
        raise(err, name) if @options.key?(name) || @arguments.key?(name)
        name
      end

      def checked_opt(name)
        checked(name, DoublicateOptionDefinitionError)
      end

      def option(mtc)
        @options[checked_opt(mtc[1])] = @options[checked_opt(mtc[2])] = mtc[3]
      end

      def simple_option(match)
        @options[checked_opt(match[1])] = match[2]
      end

      def switch(match)
        name = checked_opt(match[2])
        @options[name] = @options[checked_opt(match[1])] = "!#{name}"
      end

      def simple_switch(name)
        @options[checked_opt(name)] = "!#{name}"
      end
    end

    private_constant(:Prepare, :Commands, :CommandParser)
  end

  class InvalidCommandError < Error
    def initialize(command, name)
      super(command, "invalid command - #{name}")
    end
  end

  class ArgumentMissingError < Error
    def initialize(command, name)
      super(command, "argument missing - <#{name}>")
    end
  end

  class InvalidArgumentTypeError < Error
    def initialize(command, message, name)
      super(command, "#{message} - <#{name}>")
    end
  end

  class TooManyArgumentsError < Error
    def initialize(command)
      super(command, 'too many arguments')
    end
  end

  class UnknonwOptionError < Error
    def initialize(command, name)
      super(command, "unknown option - '#{name}'")
    end
  end

  class OptionArgumentMissingError < Error
    def initialize(command, name, option)
      super(command, "argument <#{name}> missing - '#{option}'")
    end
  end

  class DoublicateOptionDefinitionError < ArgumentError
    def initialize(name)
      super("option already defined - #{name}")
    end
  end

  class DoublicateArgumentDefinitionError < ArgumentError
    def initialize(name)
      super("argument already defined - #{name}")
    end
  end

  class NoCommandDefinedError < ArgumentError
    def initialize
      super('help text does not define a valid command')
    end
  end

  class DoublicateCommandDefinitionError < ArgumentError
    def initialize(name, line_number)
      super("command '#{name}' already defined - line #{line_number}")
    end
  end

  class NoDefaultCommandDefinedError < ArgumentError
    def initialize
      super('no default command defined')
    end
  end

  class InvalidSubcommandNameError < ArgumentError
    def initialize(default_name, bad_name)
      super("invalid sub-command name for #{default_name} - #{bad_name}")
    end
  end

  class UnknownAttributeError < ArgumentError
    def initialize(name)
      super("unknown attribute - #{name}")
    end
  end

  class UnknownAttributeConverterError < ArgumentError
    def initialize(name)
      super("unknown attribute converter - #{name}")
    end
  end

  @on_error = ->(e) { $stderr.puts e or exit e.code }

  lib_dir = __FILE__[..-4]

  autoload(:Conversion, "#{lib_dir}/conversion")
  autoload(:VERSION, "#{lib_dir}/version")

  private_constant(
    :Assemble,
    :ArgumentMissingError,
    :DoublicateArgumentDefinitionError,
    :DoublicateCommandDefinitionError,
    :DoublicateOptionDefinitionError,
    :InvalidArgumentTypeError,
    :InvalidCommandError,
    :InvalidSubcommandNameError,
    :NoCommandDefinedError,
    :NoDefaultCommandDefinedError,
    :OptionArgumentMissingError,
    :TooManyArgumentsError,
    :UnknonwOptionError,
    :UnknownAttributeError,
    :UnknownAttributeConverterError
  )
end
