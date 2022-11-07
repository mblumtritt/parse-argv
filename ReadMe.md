# ParseArgv

A command line parser that only needs your help text.

<!-- - Gem: [rubygems.org](https://rubygems.org/gems/parse-argv) -->
- Source: [github.com](https://github.com/mblumtritt/parse-argvt)
<!-- - Help: [rubydoc.info](https://rubydoc.info/gems/parse-argv) -->

## Description

Just write the help text for your application and ParseArgv will take care of your command line. It works sort of the other way around than OptParse, where you write a lot of code to get a command line parser and generated help text. ParseArgv simply takes your help text and parses the command line and presents you the results.

You can use ParseArgv for simpler programs just as well as for CLI with multi-level sub-commands (git-like commands). ParseArgv is easy to use, fast and also helps you convert the data types of command line arguments.

## TODO

This is a very early stage of the gem which means that some stuff is missing/just in development.

- [ ]  extend tests
- [ ]  add more examples

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
