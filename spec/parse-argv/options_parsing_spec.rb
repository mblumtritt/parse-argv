# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'command parsing' do
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

  context 'when help text is specified before the first usage line' do
    let(:help_text) { <<~HELP }
      This is some header text before the usage line.

      usage: test
        -s, --switch   a switch

      This is the footer text.
    HELP

    it 'includes the help header text' do
      expect(ParseArgv.from(help_text, %w[]).to_s).to eq help_text.chomp
    end
  end
end
