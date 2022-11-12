#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/parse-argv'

ARGS = ParseArgv.from <<~HELP
  ParseARGS Demo about conversions
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

puts(ARGS) or exit if ARGS.help?

puts <<~RESULT
  string    #{ARGS.as(String, :string).inspect}
  array     #{ARGS.as(Array, :array).inspect}
  filename  #{ARGS.as(:file_name, :filename).inspect}
  regexp    #{ARGS.as(Regexp, :regexp).inspect}
  integer   #{ARGS.as(Integer, :integer)}
  float     #{ARGS.as(Float, :float)}
  number    #{ARGS.as(Numeric, :number)}
  byte      #{ARGS.as(:byte, :byte)}
  date      #{ARGS.as(:date, :date)}
  time      #{ARGS.as(Time, :time)}
  file      #{ARGS.as(File, :file).inspect}
  dir       #{ARGS.as(Dir, :dir).inspect}
  files     #{ARGS.as([File], :files).inspect}
  oneof     #{ARGS.as(%w[foo bar baz], :oneof)}
RESULT
