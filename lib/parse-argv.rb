# frozen_string_literal: true

module ParseArgv
  class Error < StandardError
    attr_reader :command

    def initialize(command, message)
      @command = command
      super("#{command}: #{message}")
    end
  end

  class ArgumentMissingError < Error
    def initialize(command, name = nil)
      super(
        command,
        name.nil? ? 'argument missing' : "argument missing - <#{name}>"
      )
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

  def self.from(help_text, argv = ARGV)
    cmd = Factory.new.parse(help_text) or
      raise(ArgumentError, 'help text does not define a valid command')
    Result
      .new(cmd.name, cmd.help_text, cmd.parser.parse(argv, :help, :version))
      .tap { |result| yield(result) if block_given? }
  end

  class Parser
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

    attr_reader :command

    def initialize(command)
      @command = command
      @options = {}
      @arguments = {}
    end

    def switch(name, var_name = name)
      raise(DoublicateOptionDefinitionError, name) if known?(name)
      @options[name] = "!#{var_name}"
    end

    def option(name, var_name)
      raise(DoublicateOptionDefinitionError, name) if known?(name)
      @options[name] = var_name
    end

    def argument(name, required:)
      raise(DoublicateArgumentDefinitionError, name) if known?(name)
      @arguments[name] = required
    end

    def parse(argv, *special_commands)
      @result = {}.compare_by_identity
      arguments = parse_argv(Array.new(argv))
      process_switches
      process(arguments) unless consider?(special_commands)
      @result
    end

    private

    def consider?(special_commands)
      special_commands.any? do |name|
        @options[name.to_s] == "!#{name}" && @result[name] == true
      end
    end

    def known?(name)
      @options.key?(name) || @arguments.key?(name)
    end

    def parse_argv(argv)
      arguments = []
      while (arg = argv.shift)
        case arg
        when '--'
          return arguments + argv
        when /\A--([[[:alnum:]]-]+)\z/
          handle_option(Regexp.last_match[1], argv)
        when /\A-{1,2}([[[:alnum:]]-]+):(.+)\z/
          handle_option_arg(Regexp.last_match)
        when /\A-([[:alnum:]]+)\z/
          handle_opts(Regexp.last_match[1], argv)
        else
          arguments << arg
        end
      end
      arguments
    end

    def process(arguments)
      allow_files = nil
      @arguments.each_pair do |arg, required|
        next allow_files = required if arg == '...'
        next if arguments.first.nil? && !required
        value = arguments.shift
        raise(ArgumentMissingError.new(@command, arg)) if value.nil?
        @result[arg.to_sym] = value
      end
      assemble(allow_files, arguments)
    end

    def assemble(allow_files, arguments)
      case allow_files
      when nil
        raise(TooManyArgumentsError, @command) unless arguments.empty?
      when true
        raise(ArgumentMissingError, @command) if arguments.empty?
        @result[:additional] = arguments
      when false
        @result[:additional] = arguments unless arguments.empty?
      end
    end

    def handle_option(name, argv, pref = '-')
      key = @options[name]
      raise(UnknonwOptionError.new(@command, "#{pref}-#{name}")) if key.nil?
      return @result[key[1..].to_sym] = true if key[0] == '!'
      @result[key.to_sym] = value = argv.shift
      return unless value.nil? || value[0] == '-'
      raise(OptionArgumentMissingError.new(@command, key, "#{pref}-#{name}"))
    end

    def handle_option_arg(match)
      name = match[1]
      key = @options[name]
      if key.nil?
        raise(UnknonwOptionError.new(@command, "#{match.pre_match}#{name}"))
      end
      return @result[key[1..].to_sym] = as_boolean(match[2]) if key[0] == '!'
      @result[key.to_sym] = match[2]
    end

    def handle_opts(name, argv)
      name.each_char { |n| handle_option(n, argv, nil) }
    end

    def process_switches
      @options.each_value do |name|
        next unless name[0] == '!'
        name = name[1..].to_sym
        @result[name] = false unless @result.key?(name)
      end
    end

    def as_boolean(str)
      %w[y yes t true on].include?(str)
    end
  end

  class Result
    attr_reader :command_name, :help_text

    def initialize(command_name, help_text, args)
      @command_name = command_name
      @help_text = help_text
      @args = args
    end

    def to_h
      Hash[@args.to_a] # create a copy without compare_by_identity
    end
    alias to_hash to_h

    def respond_to_missing?(sym, _)
      @args.key?(sym) || super
    end

    def inspect
      "#{__to_s[..-2]}:#{@command} #{
        @args.map { |k, v| "#{k}: #{v}" }.join(', ')
      }>"
    end

    alias __to_s to_s
    alias to_s help_text
    private :__to_s

    private

    def method_missing(sym, *_)
      return @args.key?(sym) ? @args[sym] : super unless sym.end_with?('?')
      sym = sym[0..-2].to_sym
      @args.key?(sym) ? @args[sym] == true : super
    end
  end

  Command =
    Struct.new(:parser, :help) do
      def name
        parser.command
      end

      def help_text
        help.pop while help.last.empty?
        help.join("\n").freeze
      end
    end

  class Factory
    class UsageLineMissingError < ArgumentError
      def initialize
        super("options can only be defined after a 'usage' line")
      end
    end

    def parse(text)
      @help = []
      text.each_line(chomp: true) do |line|
        case line
        when /usage: ([[:alnum:]]+)/i
          new_command(Regexp.last_match)
        when /-([[:alnum:]]), --([[[:alnum:]]-]+)[ :]<([[:lower:]]+)>\s+\S+/
          option(Regexp.last_match)
        when /-{1,2}([[[:alnum:]]-]+)[ :]<([[:lower:]]+)>\s+\S+/
          simple_option(Regexp.last_match)
        when /-([[:alnum:]]), --([[[:alnum:]]-]+)\s+\S+/
          switch(Regexp.last_match)
        when /-{1,2}([[[:alnum:]]-]+)\s+\S+/
          simple_switch(Regexp.last_match)
        end
        @help << line
      end
      command
    end

    private

    def command
      @command || raise(UsageLineMissingError)
    end

    def option(match, parser = command.parser)
      parser.option(match[1], match[3])
      parser.option(match[2], match[3])
    end

    def simple_option(match)
      command.parser.option(match[1], match[2])
    end

    def switch(match, parser = command.parser)
      parser.switch(match[1], match[2])
      parser.switch(match[2], match[2])
    end

    def simple_switch(match)
      command.parser.switch(match[1], match[1])
    end

    def new_command(match)
      @command = Command.new(parser = Parser.new(match[1]), @help)
      match
        .post_match
        .scan(/(\[?<([[:alnum:]]+|\.{3})>\]?)/) do |(f, n)|
          parser.argument(n, required: f[0] != '[')
        end
      @command
    end
  end

  private_constant(:Factory, :Parser, :Result)
end
