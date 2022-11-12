# ParseArgv

A command line parser that only needs your help text.

- Gem: [rubygems.org](https://rubygems.org/gems/parse-argv)
- Source: [github.com](https://github.com/mblumtritt/parse-argv)
- Help: [rubydoc.info](https://rubydoc.info/gems/parse-argv)

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
- accepts an option named "format" when <kbd>-f</kbd> or <kbd>--format</kbd> are given
- defines the boolean option "verbose" when <kbd>--verbose</kbd> is given
- defines the boolean option "help" when <kbd>-h</kbd> or <kbd>--help</kbd> are given

## How To Use

Please, see the [Gem's help](https://rubydoc.info/gems/parse-argv) for detailed information, or have a look at the  [`./examples`](./examples) directory which contains some commands to play around.

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

args.infile
#=> the argument value named "infile"
```

## Help Text Syntax

The help text must follow these simple rules:

• All help text should be designed to be presented to the user as command line help.

• A command is recognized by a line with the following pattern:
```
usage: command
```

• A subcommand is recognized by a line with the following pattern:
```
usage: command subcommand
```

• Command line arguments must be enclosed with less-than/greater-than characters (<kbd><</kbd> and <kbd>></kbd>).
```
usage: command <argument>
```

• Optional arguments are enclosed in square brackets (<kbd>[</kbd> and <kbd>]</kbd>).
```
usage: command [<argument>]
```

• Arguments to be collected in arrays are marked with three dots at the end.
```
usage: command <argument>...
```
```
usage: command [<argument>...]
```

• Options start after any number of spaces with a stroke (<kbd>-</kbd>) and a single letter, or two strokes (<kbd>--</kbd>)and a word, which must be followed by a descriptive text.
```
  -s   this is a boolean option (switch)
```
```
  --switch   this is a boolean option (switch)
```

• Options that are to be specified both as a word and its abbreviation can be combined with a comma (<kbd>,</kbd>).
```
  -s, --switch   this is a boolean option (switch)
```

• Options that require an argument additionally define the name of the argument after the declaration, enclosed with less-than/greater-than characters (<kbd><</kbd> and <kbd>></kbd>).
```
  -o <option>   this is an option with the argument named "option"
```
```
  --opt <option>   this is an option with the argument named "option"
```
```
  -o, --opt <option>   this is an option with the argument named "option"
```

• If multiple subcommands are to be defined (git-like commands), the individual commands can be separated with a line beginning with a <kbd>#</kbd> character.
```
usage: command
Options and helptext for "command" here...

#

This is the help text header for the subcommand

usage: command subcommand
Options and helptext for the subcommand here...
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

