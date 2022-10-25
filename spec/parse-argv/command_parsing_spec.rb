# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'command parsing' do
  context 'parse arguments' do
    context 'when all arguments are required' do
      let(:help_text) { 'usage: test <file1> <file2>' }

      it 'accepts all parameters' do
        result = ParseArgv.from(help_text, %w[arg1 arg2])
        expect(result.file1).to eq 'arg1'
        expect(result.file2).to eq 'arg2'
      end

      it 'requires correct parameter count' do
        expect { ParseArgv.from(help_text, %w[arg1]) }.to raise_error(
          ParseArgv::Error
        )
        expect { ParseArgv.from(help_text, %w[arg1 arg2 arg3]) }.to raise_error(
          ParseArgv::Error
        )
      end
    end

    context 'when some arguments are optional' do
      let(:help_text) { 'usage: test <file1> [<file2>] <file3>' }

      it 'accepts all parameters' do
        result = ParseArgv.from(help_text, %w[arg1 arg2 arg3])
        expect(result.file1).to eq 'arg1'
        expect(result.file2).to eq 'arg2'
        expect(result.file3).to eq 'arg3'
      end

      it 'accepts minimum parameters' do
        result = ParseArgv.from(help_text, %w[arg1 arg3])
        expect(result.file1).to eq 'arg1'
        expect(result.member?(:file2)).to be false
        expect(result.file3).to eq 'arg3'
      end

      it 'requires correct parameter count' do
        expect { ParseArgv.from(help_text, %w[arg1]) }.to raise_error(
          ParseArgv::Error,
          'test: argument missing - <file3>'
        )
        expect { ParseArgv.from(help_text, %w[a1 a2 a3 a4]) }.to raise_error(
          ParseArgv::Error,
          'test: too many arguments'
        )
      end
    end

    context 'when additional arguments are required' do
      let(:help_text) { 'usage: test <file1> <files>...' }

      it 'accepts all given arguments' do
        result = ParseArgv.from(help_text, %w[arg1 arg2 arg3])
        expect(result.file1).to eq 'arg1'
        expect(result.files).to eq %w[arg2 arg3]
      end

      it 'requires additional arguments' do
        expect { ParseArgv.from(help_text, %w[arg1]) }.to raise_error(
          ParseArgv::Error,
          'test: argument missing - <files>'
        )
      end
    end

    context 'when additional arguments are optional' do
      let(:help_text) { 'usage: test <file1> [<files>...]' }

      it 'accepts all given arguments' do
        result = ParseArgv.from(help_text, %w[arg1 arg2 arg3])
        expect(result.file1).to eq 'arg1'
        expect(result.files).to eq %w[arg2 arg3]
      end

      it 'does not require additional parameters' do
        result = ParseArgv.from(help_text, %w[arg1])
        expect(result.file1).to eq 'arg1'
        expect(result.member?(:files)).to be false
      end
    end
  end

  context 'when an argument name is already used' do
    let(:help_text) { 'usage: test <file1> [<file1>]' }

    it 'raises an error' do
      expect { ParseArgv.from(help_text, []) }.to raise_error(
        ArgumentError,
        'argument already defined - file1'
      )
    end
  end

  context 'parse switches' do
    context 'when a long format and a shortcut are defined' do
      let(:help_text) { <<~HELP }
        usage: test
          -s, --switch   simple switch
      HELP

      it 'accepts the long format' do
        expect(ParseArgv.from(help_text, %w[--switch]).switch?).to be true
      end

      it 'accepts the shortcut' do
        expect(ParseArgv.from(help_text, %w[-s]).switch?).to be true
      end
    end

    context 'when only the long format is defined' do
      let(:help_text) { <<~HELP }
        usage: test
          --switch   simple switch
      HELP

      it 'accepts the long format' do
        expect(ParseArgv.from(help_text, %w[--switch]).switch?).to be true
      end
    end

    context 'when only the shortcut format is defined' do
      let(:help_text) { <<~HELP }
        usage: test
          -s   simple switch
      HELP

      it 'accepts the shortcut format' do
        expect(ParseArgv.from(help_text, %w[-s]).s?).to be true
      end
    end
  end

  context 'parse options' do
    context 'when a long format and a shortcut are defined' do
      let(:help_text) { <<~HELP }
        usage: test
          -o, --opt <option>    option with parameter
      HELP

      it 'accepts the long format' do
        expect(
          ParseArgv.from(help_text, %w[--opt option_arg]).option
        ).to eq 'option_arg'
      end

      it 'accepts the shortcut' do
        expect(
          ParseArgv.from(help_text, %w[-o option_arg]).option
        ).to eq 'option_arg'
      end
    end

    context 'when only the long format is defined' do
      let(:help_text) { <<~HELP }
        usage: test
          --opt <option>    option with parameter
      HELP

      it 'accepts the long format' do
        expect(
          ParseArgv.from(help_text, %w[--opt option_arg]).option
        ).to eq 'option_arg'
      end
    end

    context 'when only the shortcut format is defined' do
      let(:help_text) { <<~HELP }
        usage: test
          -o <option>    option with parameter
      HELP

      it 'accepts the shortcut format' do
        ParseArgv.from(help_text, %w[-o option_arg]).option
      end
    end
  end

  context 'parse options in alternative notation' do
    context 'when a long format and a shortcut are defined' do
      let(:help_text) { <<~HELP }
        usage: test
          -o, --opt:<option>    option with parameter
      HELP

      it 'accepts the long format' do
        expect(
          ParseArgv.from(help_text, %w[--opt option_arg]).option
        ).to eq 'option_arg'
      end

      it 'accepts the shortcut' do
        expect(
          ParseArgv.from(help_text, %w[-o option_arg]).option
        ).to eq 'option_arg'
      end
    end

    context 'when only the long format is defined' do
      let(:help_text) { <<~HELP }
        usage: test
          --opt:<option>    option with parameter
      HELP

      it 'accepts the long format' do
        expect(
          ParseArgv.from(help_text, %w[--opt option_arg]).option
        ).to eq 'option_arg'
      end
    end

    context 'when only the shortcut format is defined' do
      let(:help_text) { <<~HELP }
        usage: test
          -o:<option>    option with parameter
      HELP

      it 'accepts the shortcut format' do
        ParseArgv.from(help_text, %w[-o option_arg]).option
      end
    end
  end

  context 'when an option/switch name is already used' do
    let(:help_text) { <<~HELP }
      usage: test
        -s, --switch   a switch
        -s, --stop     another switch
      HELP

    it 'raises an error' do
      expect { ParseArgv.from(help_text, []) }.to raise_error(
        ArgumentError,
        'option already defined - s'
      )
    end
  end

  context 'when options are defined before usage line' do
    let(:help_text) { <<~HELP }
        -s, --switch   a switch
      usage: test
    HELP

    it 'raises an error' do
      expect { ParseArgv.from(help_text, []) }.to raise_error(
        ArgumentError,
        "options can only be defined after a 'usage' line - line 1"
      )
    end
  end

  context 'when help text is specified before the first usage line' do
    let(:help_text) { <<~HELP }
      This is some header text before the usage line.

      usage: test
        -s, --switch   a switch

      This is the footer text.
    HELP

    it 'collects the help header text' do
      expect(ParseArgv.from(help_text, %w[]).to_s).to eq help_text.chomp
    end
  end
end
