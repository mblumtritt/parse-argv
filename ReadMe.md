# ParseArgv

A command line parser that only needs your help text.

<!-- - Gem: [rubygems.org](https://rubygems.org/gems/parse-argv) -->
- Source: [github.com](https://github.com/mblumtritt/parse-argvt)
<!-- - Help: [rubydoc.info](https://rubydoc.info/gems/parse-argv) -->

## Description

Just write the help text for your application and ParseArgv will take care of the command line for you. It's kind of the reverse of OptParse, where you code a lot to get a command line parser with help text support.
ParseArgv works for simple commands, as well as for CLI with subcommands (git-like apps).

## TODO

This is a very early stage of the gem which means that some stuff is missing/just in development.

Planned extensions are missing:

- [ ]  extend tests
- [ ]  support argument conversion; not decided yet how to integrate it
- [ ]  add YARD documentation
- [ ]  add examples

<!-- ## Sample

For more samples see the [`./examples`](./examples) directory. -->

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
