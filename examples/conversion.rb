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
  string    #{ARGS[:string].as(String).inspect}
  array     #{ARGS[:array].as(Array).inspect}
  filename  #{ARGS[:filename].as(:file_name).inspect}
  regexp    #{ARGS[:regexp].as(Regexp).inspect}
  integer   #{ARGS[:integer].as(Integer)}
  float     #{ARGS[:float].as(Float)}
  number    #{ARGS[:number].as(Numeric)}
  byte      #{ARGS[:byte].as(:byte)}
  date      #{ARGS[:date].as(:date)}
  time      #{ARGS[:time].as(Time)}
  file      #{ARGS[:file].as(File).inspect}
  dir       #{ARGS[:dir].as(Dir).inspect}
  files     #{ARGS[:files].as([File]).inspect}
  oneof     #{ARGS[:oneof].as(%w[foo bar baz])}
RESULT
