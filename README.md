# ParseArgv ![version](https://img.shields.io/gem/v/parse-argv?label=)

A command line parser that only needs your help text.

- Gem: [rubygems.org](https://rubygems.org/gems/parse-argv)
- Source: [github.com](https://github.com/mblumtritt/parse-argv)
- Help: [rubydoc.info](https://rubydoc.info/gems/parse-argv/ParseArgv)

## Description

Just write the help text for your application and ParseArgv will take care of your command line. It works sort of the other way around than OptParse, where you write a lot of code to get a command line parser and generated help text. ParseArgv simply takes your help text and parses the command line and presents you the results.

You can use ParseArgv for simpler programs just as well as for CLI with multi-level sub-commands (git-like commands). ParseArgv is easy to use, fast and also helps you convert the data types of command line arguments.

## Example

The given help text

```
usage: test [options] <infile> [<outfile>]

This is just a demonstration.

options:
  -f, --format <format>   specify the format
  --verbose               enable verbose mode
  -h, --help              print this help text
```

will be interpreted as

- there is a command "test"
- which requires and argument "infile"
- optionally accepts an  second argument "outfile"
- accepts an option named "format" when `-f` or `--format` are given
- defines the boolean option "verbose" when `--verbose` is given
- defines the boolean option "help" when `-h` or `--help` are given

## How To Use

Please, see the [Gem's help](https://rubydoc.info/gems/parse-argv/ParseArgv) for detailed information, or have a look at the  [`./examples`](./examples) directory which contains some commands to play around.

The supported help text syntax and the command line interface syntax are described in the [syntax help](./syntax.md).

In general you just specify the help text and get the parsed command line:

```ruby
require 'parse-argv'

args = ParseArgv.from <<~HELP
  usage: test [options] <infile> [<outfile>]

  This is just a demonstration.

  options:
    -f, --format <format>   specify the format
    --verbose               enable verbose mode
    -h, --help              print this help text
HELP

args.verbose?
#=> true, when "--verbose" argument was specified
#=> false, when "--verbose" argument was not specified

args[:infile].as(File, :readable)
#=> file name

args.outfile?
#=> true, when second argument was specified
args.outfile
#=> second argument or nil when not specified
```

## Installation

Use [Bundler](http://gembundler.com/) to add ParseArgv in your own project:

Include in your `Gemfile`:

```ruby
gem 'parse-argv'
```

and install it by running Bundler:

```bash
bundle
```

To install the gem globally use:

```bash
gem install parse-argv
```

After that you need only a single line of code in your project to have it on board:

```ruby
require 'parse-argv'
```

