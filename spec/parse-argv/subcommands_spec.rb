# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'subcommands' do
  let(:help_text) { <<~HELP }
    ### main command:

    This is a definition for a multi-command CLI (like git).

    Usage: multi [options] <command>

    Commands:
      foo       foo command
      foo bar   foo subcommand bar
      baz       baz sample command
      help      help command

    Options:
      -h, --help      shortcut for 'help' command
      -v, --version   'version' command shortcut

    Use `multi help <command>` to get command specific help

    ### subcommand foo:

    Header text for command foo.

    Usage: multi foo [options] <parameter>

    This is the 'foo' command. Notice there is a `foo bar` subcommand.

    Options:
      -s, --switch             simpe switch (boolean option)
      -o, --option <option>    option with parameter

    #### subcommand foo bar:

    Usage: multi foo bar [options] [<files>...]

    This is the 'foo bar' command.

    Options:
      -s, --switch            simpe switch (boolean option)
      -o, --option:<option>   option with parameter

    #### subcommand baz:

    Usage: multi baz <files>...

    ###

    Usage: multi help [<command>...]

    Show help or <command> specific help.
  HELP

  context 'definition' do
    subject(:result) { ParseArgv.parse(help_text) }

    it 'defines all commands' do
      names = result.map { |info| info[:name] }
      expect(names).to eq ['multi', 'foo', 'foo bar', 'baz', 'help']
    end

    {
      'multi' => {
        command: {
          type: :argument,
          required: true
        },
        help: {
          type: :switch,
          names: %w[h help]
        },
        version: {
          type: :switch,
          names: %w[v version]
        }
      },
      'foo' => {
        parameter: {
          type: :argument,
          required: true
        },
        switch: {
          type: :switch,
          names: %w[s switch]
        },
        option: {
          type: :option,
          names: %w[o option]
        }
      },
      'foo bar' => {
        files: {
          type: :argument_array,
          required: false
        },
        switch: {
          type: :switch,
          names: %w[s switch]
        },
        option: {
          type: :option,
          names: %w[o option]
        }
      },
      'baz' => {
        files: {
          type: :argument_array,
          required: true
        }
      },
      'help' => {
        command: {
          type: :argument_array,
          required: false
        }
      }
    }.each_pair do |name, args|
      let(:command) { result.find { |info| info[:name] == name } }
      let(:arguments) { args }

      it "defines a command '#{name}'" do
        expect(command).not_to be_nil
      end

      it "defines correct arguments for '#{name}'" do
        expect(command[:arguments]).to eq arguments
      end
    end
  end

  context 'behavior' do
    subject(:result) { ParseArgv.from(help_text, argv) }

    context 'when no subcommand command was specified' do
      let(:argv) { [] }

      it 'raises an error' do
        expect { result }.to raise_error(
          ParseArgv::Error,
          'multi: argument missing - <command>'
        )
      end
    end

    context 'main: multi --help' do
      let(:argv) { %w[-h] }

      it 'returns the main command' do
        expect(result.current_command.name).to eq 'multi'
      end

      it 'returns correct options' do
        expect(result.help?).to be true
        expect(result.version?).to be false
      end
    end

    context 'main: multi --version' do
      let(:argv) { %w[-v] }

      it 'returns the main command' do
        expect(result.current_command.name).to eq 'multi'
      end

      it 'returns correct options' do
        expect(result.help?).to be false
        expect(result.version?).to be true
      end
    end

    context 'subcommand: foo' do
      let(:argv) { %w[foo -s -o opt arg1] }

      it 'returns the subcommand' do
        expect(result.current_command.name).to eq 'foo'
      end

      it 'returns correct options' do
        expect(result.switch?).to be true
        expect(result.option).to eq 'opt'
        expect(result.parameter).to eq 'arg1'
      end
    end

    context 'subcommand: foo bar' do
      let(:argv) { %w[foo bar -s -o opt arg1] }

      it 'returns the subcommand' do
        expect(result.current_command.name).to eq 'foo bar'
      end

      it 'returns correct options' do
        expect(result.switch?).to be true
        expect(result.option).to eq 'opt'
        expect(result.files).to eq %w[arg1]
      end
    end

    context 'subcommand: help' do
      let(:argv) { %w[help] }

      it 'returns the subcommand' do
        expect(result.current_command.name).to eq 'help'
      end

      it 'returns correct arguments' do
        expect(result.member?(:command)).to be false
      end
    end

    context 'subcommand: help foo bar' do
      let(:argv) { %w[help foo bar] }

      it 'returns the subcommand' do
        expect(result.current_command.name).to eq 'help'
      end

      it 'returns correct arguments' do
        expect(result.command).to eq %w[foo bar]
      end
    end
  end
end
