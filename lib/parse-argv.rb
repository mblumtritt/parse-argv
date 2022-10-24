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

  class UsageLineMissingError < ArgumentError
    def initialize
      super("options can only be defined after a 'usage' line")
    end
  end

  class NoCommandDefinedError < ArgumentError
    def initialize
      super('help text does not define a valid command')
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

  class << self
    def from(help_text, argv = ARGV)
      commands = Factory.new.parse(help_text)
      raise(NoCommandDefinedError) if commands.empty?
      result = find_command_for(argv, commands).to_result(argv, commands)
      block_given? ? yield(result) : result
    end

    private

    def find_command_for(argv, commands)
      default = checked_commands(commands)
      result = find_command(argv, default.name, commands) || default
      commands.unshift(default)
      result
    end

    def find_command(argv, default_name, commands)
      argv
        .size
        .downto(1) do |i|
          name = argv.take(i).unshift(default_name).join(' ')
          cmd = commands.find { |command| command.name == name } or next
          argv.shift(i)
          return cmd
        end
      nil
    end

    def checked_commands(commands)
      default = commands.find { |cmd| cmd.name.index(' ').nil? }
      raise(NoDefaultCommandDefinedError) if default.nil?
      commands.delete(default)
      prefix = "#{default.name} "
      bad = commands.find { |cmd| !cmd.name.start_with?(prefix) }
      return default if bad.nil?
      raise(InvalidSubcommandNameError.new(default.name, bad.name))
    end
  end

  class Factory
    def parse(text)
      @commands = []
      @help = []
      text.each_line(chomp: true) do |line|
        case line
        when /usage: (\w+([ \w]+)?)/i
          new_command(Regexp.last_match)
        when /\A\s+-([[:alnum:]]), --([[[:alnum:]]-]+)[ :]<([[:lower:]]+)>\s+\S+/
          option(Regexp.last_match)
        when /\A\s+-{1,2}([[[:alnum:]]-]+)[ :]<([[:lower:]]+)>\s+\S+/
          simple_option(Regexp.last_match)
        when /\A\s+-([[:alnum:]]), --([[[:alnum:]]-]+)\s+\S+/
          switch(Regexp.last_match)
        when /\A\s+-{1,2}([[[:alnum:]]-]+)\s+\S+/
          simple_switch(Regexp.last_match[1])
        end
        @help << line
      end
      @commands
    end

    private

    def command
      @command || raise(UsageLineMissingError)
    end

    def option(match)
      command.option(match[1], match[3])
      command.option(match[2], match[3])
    end

    def simple_option(match)
      command.option(match[1], match[2])
    end

    def switch(match)
      command.switch(match[1], match[2])
      command.switch(match[2], match[2])
    end

    def simple_switch(name)
      command.switch(name, name)
    end

    def new_command(match)
      name = match[1].rstrip
      @help = [] unless @commands.empty?
      @command = CommandParser.new(name, @help)
      define_arguments(@command, match.post_match)
      @commands << @command
    end

    def define_arguments(parser, str)
      str.scan(/(\[?<([[:alnum:]]+)>\]?|\[?\.{3}\]?)/) do |(f, n)|
        parser.argument(n || '...', required: f[0] != '[')
      end
    end
  end

  class Command
    attr_reader :name

    def initialize(name, help)
      @name = name
      @help = help
    end

    def help
      return @help if @help.is_a?(String)
      @help.pop while @help.last.empty?
      @help = @help.join("\n").freeze
    end
  end

  class CommandParser < Command
    def initialize(name, help)
      super
      @options = {}
      @arguments = {}
    end

    def switch(name, var_name)
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

    def parse(argv)
      @result = {}.compare_by_identity
      arguments = parse_argv(Array.new(argv))
      process_switches
      process(arguments) unless help?
      @result
    end

    def to_result(argv, all_commands)
      Result.new(name, help, parse(argv), all_commands)
    end

    def simplify
      Command.new(@name, @help)
    end

    private

    def help?
      name.index(' ').nil? &&
        (@result[:help] == true || @result[:version] == true)
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
      allow_files = @arguments.delete('...')
      while arguments.size < @arguments.size
        key = rightmost_nonrequired_argument and next @arguments.delete(key)
        raise(ArgumentMissingError.new(@name, @arguments.keys.last))
      end
      argument_results(arguments)
      if arguments.empty?
        raise(ArgumentMissingError, @name) if allow_files
      else
        raise(TooManyArgumentsError, @name) if allow_files.nil?
        @result[:additional] = arguments
      end
    end

    def argument_results(args)
      @arguments.each_key { |name| @result[name.to_sym] = args.shift }
    end

    def rightmost_nonrequired_argument
      @arguments.keys.reverse_each { |key| return key unless @arguments[key] }
      nil
    end

    def handle_option(name, argv, pref = '-')
      key = @options[name]
      raise(UnknonwOptionError.new(@name, "#{pref}-#{name}")) if key.nil?
      return @result[key[1..].to_sym] = true if key[0] == '!'
      @result[key.to_sym] = value = argv.shift
      return unless value.nil? || value[0] == '-'
      raise(OptionArgumentMissingError.new(@name, key, "#{pref}-#{name}"))
    end

    def handle_option_arg(match)
      name = match[1]
      key = @options[name] or
        raise(UnknonwOptionError.new(@name, "#{match.pre_match}#{name}"))
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
    attr_reader :command_name, :help_text, :all_commands

    def initialize(command_name, help_text, args, all_commands)
      @command_name = command_name
      @help_text = help_text
      @args = args
      @all_commands = all_commands.map!(&:simplify).sort_by(&:name).freeze
    end

    def member?(name)
      @args.key?(name.to_sym)
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

  private_constant(*(constants - [:Error]))
end
