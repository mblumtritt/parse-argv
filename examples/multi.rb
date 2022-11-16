#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/parse-argv'

ARGS = ParseArgv.from <<~HELP
  ParseARGS Demo for a CLI with subcommands
  This example demonstrates a CLI with subcommands. It processes an imganinary
  key/value store that can be synchronized with a server.

  usage: multi <command>

  commands:
    var             get a variable
    var add         add a variable
    var remove      remove a variable
    push            push all vars
    pull            pull all vars
    help            show command specific help
    -h, --help      show this help
    -v, --version   show version information

  Play with different command line parameters and options to see how it works!

  usage: multi var <name>

  Get variable <name>.

  usage: multi var add [options] <name> <value>...

  Add a variable <name> with given <value>.

  options:
    -f, --force   allow to overwrite existing variable <name>

  usage: multi var remove <name>

  Remove variable <name>.

  usage: multi push [options] <url>

  Push all variables to server at <url>.

  options:
    -t, --token <token>   user token
    -f, --force           force push

  usage: multi pull [options] <url>

  Pull all variables from server at <url>.

  options:
    -t, --token <token>   user token
    -f, --force           force pull (override local variables)

  usage: multi help [<command>...]

  Show help for given <command>.
HELP

case ARGS.current_command.name
when 'multi'
  puts(ARGS.help? ? ARGS : 'multi sample v1.0.0')
when 'help'
  if ARGS.command?
    command = ARGS.find_command(ARGS.command)
    ARGS.error!("unknown command - #{ARGS.command.join(' ')}") if command.nil?
    puts(command.help)
  else
    puts(ARGS.main_command.help)
  end
else
  puts "command '#{ARGS.current_command}':"
  arguments = ARGS.to_h
  width = arguments.keys.max_by(&:size).size + 3
  arguments.each_pair do |name, value|
    puts("   #{name.to_s.ljust(width)}#{value.inspect}")
  end
end
