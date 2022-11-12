#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/parse-argv'

ARGS = ParseArgv.from <<~HELP
  Test the syntax of your help text for ParseArgv.

  Usage: check [options] <files>...

  Options:
    -f, --format <format>   display format: default, json, usage
    -c, --command <name>    display command with <name> only
    -h, --help              display this help
    -v, --version           display version information
HELP

puts(ARGS) or exit if ARGS.help?
puts("check v#{ParseArgv::VERSION}") or exit if ARGS.version?

cmds =
  begin
    ParseArgv.parse(ARGS.as(:file_content, :files).join("\n"))
  rescue ArgumentError => e
    ARGS.error!("invalid syntax - #{e}")
  end

def find_command(all, name)
  command = all.find { |cmd| cmd[:full_name] == name || cmd[:name] == name }
  command or ARGS.error!("no such command - #{name}")
end

cmds = [find_command(cmds, ARGS.as(:string, :name))] if ARGS.exist?(:name)

module Format
  class Json
    def self.show(commands)
      commands.each { |command| command.delete(:help) }
      require('json')
      puts(JSON.dump(commands))
    end
  end

  class Usage
    def self.show(commands)
      puts(commands.map { |command| new(command) }.join("\n"))
    end

    def initialize(command)
      @command = command
    end

    def to_s
      name, args = @command.fetch_values(:full_name, :arguments)
      ret = "usage: #{name}"
      args.each_pair { |name, info| ret << as_str(name, info) }
      ret
    end

    def as_str(name, info)
      case info[:type]
      when :argument
        info[:required] ? " <#{name}>" : " [<#{name}>]"
      when :argument_array
        info[:required] ? " <#{name}>..." : " [<#{name}>...]"
      when :option
        names = info[:names].map { |n| n.size == 1 ? "-#{n}" : "--#{n}" }
        " [#{names.join(', ')} <#{name}>]"
      when :switch
        names = info[:names].map { |n| n.size == 1 ? "-#{n}" : "--#{n}" }
        " [#{names.join(', ')}]"
      end
    end
  end

  class Default < Usage
    def self.show(commands)
      puts(commands.map { |command| new(command) }.join("\n\n"))
    end

    def to_s
      full_name, name, args =
        @command.fetch_values(:full_name, :name, :arguments)
      ret = ["#{full_name == name ? 'Command' : 'Subcommand'}: #{name}"]
      return ret if args.empty?
      width = args.keys.max_by(&:size).size
      args.each_pair do |name, info|
        ret << "   #{name.to_s.ljust(width)}   #{as_str(info)}"
      end
      ret.join("\n")
    end

    def as_str(info)
      case info[:type]
      when :argument
        info[:required] ? 'argument: required' : 'argument'
      when :argument_array
        info[:required] ? 'arguments array: required' : 'arguments array'
      when :option, :switch
        names = info[:names].map { |n| n.size == 1 ? "-#{n}" : "--#{n}" }
        "#{info[:type]} #{names.join(', ')}"
      end
    end
  end
end

Format.const_get(
  ARGS.as(%w[default json usage], :format, default: 'default').capitalize
).show(cmds)
