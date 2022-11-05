# frozen_string_literal: true

require_relative '../lib/parse-argv'

Argv = ParseArgv.from <<~HELP
  ParseArgv Demo for a CLI with subcommands
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

case Argv.current_command.name
when 'multi'
  puts(Argv.help? ? Argv : 'multi sample v1.0.0')
when 'help'
  if Argv.member?(:command)
    command = Argv.find_command(Argv.command)
    Argv.error!("unknown command - #{Argv.command.join(' ')}") if command.nil?
    puts(command.help)
  else
    puts(Argv.main_command.help)
  end
else
  puts "command '#{Argv.current_command}':"
  attributes = Argv.to_h
  unless attributes.empty?
    width = attributes.keys.max_by(&:size).size + 3
    attributes.each_pair do |name, value|
      puts("   #{name.to_s.ljust(width)}#{value.inspect}")
    end
  end
end
