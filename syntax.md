# ParseArgv Syntax

- [Help Text Syntax](#help-text-syntax)
- [Command Line Syntax](#command-line-syntax)

## Help Text Syntax

A help text must follow these simple rules:

• All help text should be designed to be presented to the user as command line help.

• A command is recognized by a line with the following pattern:
```
usage: command
```

• A subcommand is recognized by a line with the following pattern:
```
usage: command subcommand
```

• Command line arguments must be enclosed with less-than/greater-than characters (`<` and `>`).
```
usage: command <argument>
```

• Optional arguments are enclosed in square brackets (`[` and `]`).
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

• Options start after any number of spaces with a stroke (`-`) and a single letter, or two strokes (`--`)and a word, which must be followed by a descriptive text.
```
  -s   this is a boolean option (switch)
```
```
  --switch   this is a boolean option (switch)
```

• Options that are to be specified both as a word and its abbreviation can be combined with a comma (`,`).
```
  -s, --switch   this is a boolean option (switch)
```

• Options that require an argument additionally define the name of the argument after the declaration, enclosed with less-than/greater-than characters (`<` and `>`).
```
  -o <option>   this is an option with the argument named "option"
```
```
  --opt <option>   this is an option with the argument named "option"
```
```
  -o, --opt <option>   this is an option with the argument named "option"
```

• If multiple subcommands are to be defined (git-like commands), the individual commands can be separated with a line beginning with a `#` character.
```
usage: command
Options and helptext for "command" here...

#

This is the help text header for the subcommand

usage: command subcommand
Options and helptext for the subcommand here...
```

## Command Line Syntax

### Simple Arguments

A command line program using ParseArgv accepts all required and optional parameters as expected. The user will be notified of missing or excess parameters, if any.

Definition example:

```
usage: sample <infile> [<template>] <outfile>
```

The `<infile>` and `<outfile>` parameters are required. If they are not specified, the user will be notified.

```shell
sample ./source.md ./out.html
# ok, infile: "./source.md", outfile: "./out.html"

sample ./source.md
# error: "sample: argument missing - <outfile>"
```

If three parameters are specified in this example, the optional third parameter is also accepted.

```shell
sample ./source.md ./template.yaml ./out.html
# ok, infile: "./source.md", template: "./template.yaml", outfile: "./out.html"
```

If too many parameters are specified, the user will be notified.

```shell
sample ./source.md ./template.yaml ./out.html ./some.txt
# error: "sample: too many arguments"
```

### Options

Consider the following definition example:

```
usage: sample <infile>

options:
  -o, --out <outfile>         specify output file name
  -t, --template <template>   use given template
  -c. --colors                enable color mode
  -v, --verbose               enable verbose mode
```

Here the user must specify a `<infile>` parameter, can add optional (named) arguments (`<outfile>` and `<template>`) and select parameterless options (`<colors>` and `verbose`).

Since `<infile>`is a required argument, it must always be specified, all other specifications are optional.

```shell
sample ./source.md
# ok, infile: "./source.md"

sample ./source.md --out ./result.html -c
# ok, infile: "./source.md", outfile: "./result.html", colors: true
```

The short forms of the options can also be combined.

```shell
sample ./source.md -voc ./result.html
# ok, infile: "./source.md", outfile: "./result.html", colors: true, verbose: true
```

To write down the affiliation of named parameters more clearly, the following notation is allowed.

```shell
sample ./source.md --out:./result.html -t=nice.yaml
# ok, infile: "./source.md", outfile: "./result.html", template: "nice.yaml"
```

Parameterless options can be understood as switches. Therefore it is possible to write them down like this:

```shell
sample ./source.md --colors:on -v:off
# ok, infile: "./source.md", colors: true, verbose: false
```
