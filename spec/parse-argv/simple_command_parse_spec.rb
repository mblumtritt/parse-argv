# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'simple command parsing' do
  context 'parse boolean options' do
    context 'when a long format and a shortcut are defined' do
      let(:help_text) { <<~HELP }
        usage: test
        -o, --option    boolean option
      HELP

      it 'accepts the long format' do
        expect(ParseArgv.from(help_text, %w[--option]).option?).to be true
      end

      it 'accepts the shortcut' do
        expect(ParseArgv.from(help_text, %w[-o]).option?).to be true
      end
    end

    context 'when only the long format is defined' do
      let(:help_text) { <<~HELP }
        usage: test
        --option    boolean option
      HELP

      it 'accepts the long format' do
        expect(ParseArgv.from(help_text, %w[--option]).option?).to be true
      end
    end

    context 'when only the shortcut format is defined' do
      let(:help_text) { <<~HELP }
        usage: test
        -o    boolean option
      HELP

      it 'accepts the shortcut format' do
        expect(ParseArgv.from(help_text, %w[-o]).o?).to be true
      end
    end
  end

  context 'parse options with arguments' do
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

  context 'parse options with arguments in alternative notation' do
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

    context 'when additional files are required' do
      let(:help_text) { 'usage: test <file1> ...' }

      it 'accepts all given arguments' do
        result = ParseArgv.from(help_text, %w[arg1 arg2 arg3])
        expect(result.file1).to eq 'arg1'
        expect(result.additional).to eq %w[arg2 arg3]
      end

      it 'requires additional files' do
        expect { ParseArgv.from(help_text, %w[arg1]) }.to raise_error(
          ParseArgv::Error,
          'test: argument missing'
        )
      end
    end

    context 'when additional files are optional' do
      let(:help_text) { 'usage: test <file1> [...]' }

      it 'accepts all given arguments' do
        result = ParseArgv.from(help_text, %w[arg1 arg2 arg3])
        expect(result.file1).to eq 'arg1'
        expect(result.additional).to eq %w[arg2 arg3]
      end

      it 'does not require additional parameters' do
        result = ParseArgv.from(help_text, %w[arg1])
        expect(result.file1).to eq 'arg1'
        expect(result.member?(:additional)).to be false
      end
    end
  end
end
