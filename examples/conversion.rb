# frozen_string_literal: true

require_relative '../lib/parse-argv'

Argv = ParseArgv.from <<~HELP
  ParseArgv Demo about conversions
  This example demonstrates the build-in conversions.

  usage: conversion [options]

  options:
    -s, --string <string>      accept any non-empty String
    -a, --array <array>        accept an array of String
    -r, --regexp <regexp>      convert to a regular expression
    -i, --integer <integer>    convert to Integer
    -f, --float <float>        convert to Float
    -n, --number <number>      convert to Numeric (Integer or Float)
    -b, --byte <byte>          convert to number of byte
    -d, --date <date>          convert to Date
    -t, --time <time>          convert to Time
    -N, --filename <filename>  convert to a (relative) file name String
    -F, --fname <file>         accept name of an existing file
    -D, --dname <dir>          accept name of an existing directory
    -A, --files <files>        accept an array of file names
    -1, --one <oneof>          accept one of 'foo', 'bar', 'baz'
    -h, --help                 print this help
HELP

puts(Argv) or exit if Argv.help?

puts <<~RESULTS
  Results:
    string    #{Argv.as(String, :string).inspect}
    array     #{Argv.as(Array, :array).inspect}
    filename  #{Argv.as(:file_name, :filename).inspect}
    regexp    #{Argv.as(Regexp, :regexp).inspect}
    integer   #{Argv.as(Integer, :integer)}
    float     #{Argv.as(Float, :float)}
    number    #{Argv.as(Numeric, :number)}
    byte      #{Argv.as(:byte, :byte)}
    date      #{Argv.as(:date, :date)}
    time      #{Argv.as(Time, :time)}
    file      #{Argv.as(File, :file).inspect}
    dir       #{Argv.as(Dir, :dir).inspect}
    files     #{Argv.as([File], :files).inspect}
    oneof     #{Argv.as(%w[foo bar baz], :oneof)}
RESULTS
