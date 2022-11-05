# frozen_string_literal: true

require_relative '../lib/parse-argv'

ARGS = ParseArgv.from <<~HELP
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

puts(ARGS) or exit if ARGS.help?
puts('simple v1.0.0') or exit if ARGS.version?

puts('parameters:')
parameters = ARGS.to_h
width = parameters.keys.max_by(&:size).size + 3
parameters.each_pair do |name, value|
  puts("   #{name.to_s.ljust(width)}#{value.inspect}")
end
