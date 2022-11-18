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

