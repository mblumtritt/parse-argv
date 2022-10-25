# frozen_string_literal: true

require_relative '../lib/parse-argv'

ParseArgv.from(<<~HELP) do |args|

Simple ParseArgv Demo

This is a demo for the command `simple`, which requires an <input> argument and
accepts optional an <output> argument. It accepts also some options.

Usage: simple [options] <input> [<output>]

Options:
  -f, --format <fmt>    select a format
  -c, --count <count>   set a count

The command's options can be defined in different paragraphs.

More Options:
  -h, --help      display this help
  -v, --version   display version information
  --verbose       enable verbose mode

Play with different command line parameters and options to see how it works!

HELP
  puts(args) or exit if args.help?
  puts("#{args.command_name} v1.0.0") or exit if args.version?
  puts("#{args.command_name}:")
  attributes = args.to_h
  width = attributes.keys.max_by(&:size).size + 3
  attributes.each_pair do |name, value|
    puts("   #{name.to_s.ljust(width)}#{value.inspect}")
  end
end
