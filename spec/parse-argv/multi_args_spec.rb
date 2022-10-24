# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'multi-command arguments handling' do
  subject(:result) { ParseArgv.from(help_text, argv) }

  let(:help_text) { <<~HELP }
    This is a definition for a multi-command CLI (like git).

    Usage: multi [options] <command>

    Commands:
      foo       foo command
      foo bar   foo sub-command bar
      baz       baz sample command
      help      help command
      version   version command

    Options:
      -h, --help      shortcut for 'help' command
      -v, --version   'version' command shortcut

    Use `multi help <command>` to get command specific help

    Usage: multi foo [options] <parameter>

    This is the 'foo' command. Notice there is a `foo bar` sub-command.

    Options:
      -s, --switch             simpe switch (boolean option)
      -o, --option <option>    option with parameter

    Usage: multi foo bar [options] [<files>...]

    This is the 'foo bar' command.

    Options:
      -s, --switch            simpe switch (boolean option)
      -o, --option:<option>   option with parameter

    Usage: multi help [<command>...]

    Show help or <command> specific help.
  HELP

  context 'when no sub-command command was specified' do
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
      expect(result.command_name).to eq 'multi'
    end

    it 'returns correct options' do
      expect(result.help?).to be true
      expect(result.version?).to be false
    end

    it 'returns all commands' do
      expect(result.all_commands.map(&:name)).to eq [
           'multi',
           'multi foo',
           'multi foo bar',
           'multi help'
         ]
    end
  end

  context 'main: multi --version' do
    let(:argv) { %w[-v] }

    it 'returns the main command' do
      expect(result.command_name).to eq 'multi'
    end

    it 'returns correct options' do
      expect(result.help?).to be false
      expect(result.version?).to be true
    end
  end

  context 'sub-command: foo' do
    let(:argv) { %w[foo -s -o opt arg1] }

    it 'returns the sub-command' do
      expect(result.command_name).to eq 'multi foo'
    end

    it 'returns correct options' do
      expect(result.switch?).to be true
      expect(result.option).to eq 'opt'
      expect(result.parameter).to eq 'arg1'
    end
  end

  context 'sub-command: foo bar' do
    let(:argv) { %w[foo bar -s -o opt arg1] }

    it 'returns the sub-command' do
      expect(result.command_name).to eq 'multi foo bar'
    end

    it 'returns correct options' do
      expect(result.switch?).to be true
      expect(result.option).to eq 'opt'
      expect(result.files).to eq %w[arg1]
    end
  end

  context 'sub-command: help' do
    let(:argv) { %w[help] }

    it 'returns the sub-command' do
      expect(result.command_name).to eq 'multi help'
    end

    it 'returns correct options' do
      expect(result.member?(:command)).to be false
    end
  end

  context 'sub-command: help foo bar' do
    let(:argv) { %w[help foo bar] }

    it 'returns the sub-command' do
      expect(result.command_name).to eq 'multi help'
    end

    it 'returns correct options' do
      expect(result.command).to eq %w[foo bar]
    end
  end
end
