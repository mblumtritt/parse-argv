# frozen_string_literal: true

module ParseArgv
  class Error < StandardError
    attr_reader :command

    def initialize(command, message)
      @command = command
      super("#{command.full_name}: #{message}")
    end
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
    def initialize(line_number)
      super(
        "options can only be defined after a 'usage' line - line #{line_number}"
      )
    end
  end

  class NoCommandDefinedError < ArgumentError
    def initialize(line_number)
      super("help text does not define a valid command - line #{line_number}")
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

  def self.from(help_text, argv = ARGV)
    command = Assembler.call(help_text, argv)
    block_given? ? yield(command) : command
  rescue Error => e
    @on_error&.call(e) or raise
  end

  def self.on_error(&block)
    @on_error = block
  end

  @on_error = ->(e) { $stderr.puts e or exit 1 }

  class Assembler
    def self.call(help_text, argv)
      new.parse(help_text).command_from(Array.new(argv))
    end

    def parse(help_text)
      @commands = []
      @help = []
      @line_number = 0
      help_text.each_line(chomp: true) do |line|
        @line_number += 1
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
      self
    end

    def command_from(argv)
      raise(NoCommandDefinedError, @line_number) if @commands.empty?
      default = extract_default_command
      if @commands.empty?
        default.to_result(argv, [default.to_cmd].freeze)
      elsif argv.empty?
        as_result(argv, default)
      else
        sub_command_from(default, argv)
      end
    end

    private

    def as_result(argv, found, default = found)
      found.to_result(
        argv,
        @commands.map!(&:to_cmd).sort_by(&:name).unshift(default.to_cmd)
      )
    end

    def sub_command_from(default, argv)
      prepare_subcommands(default)
      args = argv.take_while { |arg| arg[0] != '-' }
      found, prefix = args.empty? ? default : find_command(args)
      raise(InvalidCommandError.new(default, args.first)) if found.nil?
      argv.shift(prefix) if prefix
      as_result(argv, found, default)
    end

    def find_command(args)
      args
        .size
        .downto(1) do |i|
          name = args.take(i).join(' ')
          cmd = @commands.find { |command| command.name == name } or next
          return cmd, i
        end
      nil
    end

    def prepare_subcommands(default)
      prefix = "#{default.full_name} "
      @commands.each do |cmd|
        next cmd.name.delete_prefix!(prefix) if cmd.name.start_with?(prefix)
        raise(InvalidSubcommandNameError.new(default.name, cmd.name))
      end
    end

    def extract_default_command
      default = @commands.find { |cmd| cmd.name.index(' ').nil? }
      raise(NoDefaultCommandDefinedError) if default.nil?
      @commands.delete(default)
    end

    def command
      @command || raise(UsageLineMissingError, @line_number)
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
        type = all[0] == '[' ? 'o' : 'r'
        parser.argument(name.to_sym, type + (cons.nil? ? 's' : 'a'))
      end
    end
  end

  class Command
    attr_reader :full_name, :name

    def initialize(name, help, short = nil)
      @full_name = name.freeze
      @name = short || +@full_name
      @help = help
    end

    def help
      return @help if @help.is_a?(String)
      @help.shift while @help.first.empty?
      @help.pop while @help.last.empty?
      @help = @help.join("\n").freeze
    end

    def inspect
      "#{__to_s[..-2]} #{@full_name}>"
    end

    alias __to_s to_s
    private :__to_s
    alias to_s help
  end

  class AllCommands
    def initialize(commands)
      @commands = commands
    end

    def main
      @commands.first
    end

    def names
      @commands.map(&:name)
    end

    def each(&block)
      @commands.each(&block)
    end

    def find(name)
      name = name.is_a?(Array) ? name.join(' ') : name.to_s
      @commands.find { |cmd| cmd.name == name }
    end

    def inspect
      "#{__to_s[..-2]} #{self}>"
    end

    alias __to_s to_s
    private :__to_s

    def to_s
      names.inspect
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

    def argument(name, type)
      raise(DoublicateArgumentDefinitionError, name) if known?(name)
      @arguments[name] = type
    end

    def parse(argv)
      @result = {}.compare_by_identity
      arguments = parse_argv(argv)
      process_switches
      process(arguments) unless help?
      @result
    end

    def to_result(argv, all_commands)
      argv = parse(argv)
      me = all_commands.find { |cmd| cmd.full_name == @full_name }
      Result.new(me, AllCommands.new(all_commands), argv)
    end

    def to_cmd
      Command.new(@full_name, @help, @name)
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
          process_option(Regexp.last_match[1], argv)
        when /\A-{1,2}([[[:alnum:]]-]+):(.+)\z/
          process_option_arg(Regexp.last_match)
        when /\A-([[:alnum:]]+)\z/
          process_opts(Regexp.last_match[1], argv)
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
        when 'os'
          argv.shift unless argv.empty?
        when 'oa'
          argv.shift(argv.size) unless argv.empty?
        when 'rs'
          argv.shift or raise(ArgumentMissingError.new(self, key))
        when 'ra'
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
        next @arguments.delete(keys.delete(nonreq)) if nonreq
        raise(ArgumentMissingError.new(self, @arguments.keys.last))
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
    attr_reader :_command, :all_commands

    def initialize(command, all_commands, args)
      @_command = command
      @all_commands = all_commands
      @args = args
    end

    def command_name
      @_command.name
    end

    def help_text
      @_command.help
    end

    def member?(name)
      @args.key?(name.to_sym)
    end

    def [](name)
      @args[name.to_sym]
    end

    def to_h
      Hash[@args.to_a] # create a copy without compare_by_identity
    end
    alias to_hash to_h

    def respond_to_missing?(sym, _)
      @args.key?(sym) || super
    end

    def inspect
      "#{__to_s[..-2]}:#{@_command.full_name} #{
        @args.map { |k, v| "#{k}: #{v}" }.join(', ')
      }>"
    end

    alias __to_s to_s
    private :__to_s
    alias to_s help_text

    private

    def method_missing(sym, *_)
      return @args.key?(sym) ? @args[sym] : super unless sym.end_with?('?')
      sym = sym[0..-2].to_sym
      @args.key?(sym) ? @args[sym] == true : super
    end
  end

  private_constant(*(constants - [:Error]))
end
