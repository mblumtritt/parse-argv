# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'arguments parsing' do
  subject(:result) { ParseArgv.from(help_text, argv) }

  let(:help_text) { <<~HELP }
    This is a demo for the command 'simple', which accepts some options, an
    optional <input> name and a required <output> name.

    Usage: test [options] <input> [<output>]

    Options need not to be defined in one paragraph, multiple definitions are
    allowed.

    Options:
      -s, --switch         defines a (boolean) switch named 'switch'
      -n, --next           defines a (boolean) switch named 'next'
      -o, --opt <option>   defines an option named 'option'
      -p, --pref <prefix>  defines an option named 'prefix'

    There are two special switches for simple commands, which prevent
    further parameter parsing to prefer handling of 'help' and 'version' as a
    kind of sub-commands. When these are defined, then you should test for these
    first.

    More Options:
      -h, --help           "special" switch named 'help'
      -v, --version        "special" switch named 'version'
  HELP

  context 'when a required argument is missing' do
    let(:argv) { [] }

    it 'raises an ParseArgv::Error' do
      expect { result }.to raise_error(
        ParseArgv::Error,
        'test: argument missing - <input>'
      )
    end

    context 'when parameterless <help> option is given' do
      let(:argv) { %w[--help] }

      it 'checks no arguments' do
        expect(result.help?).to be true
      end
    end

    context 'when parameterless <version> option is given' do
      let(:argv) { %w[-v] }

      it 'checks no arguments' do
        expect(result.version?).to be true
      end
    end
  end

  context 'when too many arguments are given' do
    let(:argv) { %w[input_arg output_arg evil_arg] }

    it 'raises an ParseArgv::Error' do
      expect { result }.to raise_error(
        ParseArgv::Error,
        'test: too many arguments'
      )
    end
  end

  context 'when only required <input> is given' do
    let(:argv) { %w[input_arg] }

    context 'attribute existence' do
      it 'confirms if an attribute exists' do
        expect(result.member?('switch')).to be true
        expect(result.member?(:next)).to be true
        expect(result.member?(:help)).to be true
        expect(result.member?(:version)).to be true
        expect(result.member?(:input)).to be true
      end

      it 'does not confirm if an attribute does not exist' do
        expect(result.member?('option')).to be false
        expect(result.member?(:prefix)).to be false
        expect(result.member?(:output)).to be false
        expect(result.member?(:foo)).to be false
      end
    end

    it 'defines custom attributes' do
      expect(result.input).to eq 'input_arg'
      expect(result.switch?).to be false
    end

    it 'can be converted to Hash' do
      expect(result.to_h).to eq(
        input: 'input_arg',
        switch: false,
        next: false,
        help: false,
        version: false
      )
    end
  end

  context 'when all standard options are configured' do
    let(:argv) do
      %w[-s --next --opt option_arg -p prefix_arg input_arg output_arg]
    end

    it 'parses all attributes correctly' do
      expect(result.to_h).to eq(
        input: 'input_arg',
        output: 'output_arg',
        switch: true,
        next: true,
        option: 'option_arg',
        prefix: 'prefix_arg',
        help: false,
        version: false
      )
    end
  end

  context 'when short hand options are used' do
    let(:argv) { %w[-snop option_arg prefix_arg input_arg output_arg] }

    it 'allows to condense the options' do
      expect(result.to_h).to eq(
        input: 'input_arg',
        output: 'output_arg',
        switch: true,
        next: true,
        option: 'option_arg',
        prefix: 'prefix_arg',
        help: false,
        version: false
      )
    end
  end

  context 'when alternative option value assignment is used' do
    let(:argv) do
      %w[-s:true --next:on -o:option_arg --pref:prefix_arg input_arg]
    end

    it 'allows to use alternative option value assignment' do
      expect(result.to_h).to eq(
        input: 'input_arg',
        switch: true,
        next: true,
        option: 'option_arg',
        prefix: 'prefix_arg',
        help: false,
        version: false
      )
    end
  end

  context 'when a required option parameter is expected' do
    let(:argv) { %w[input_arg -o] }

    it 'raises an error' do
      expect { result }.to raise_error(
        ParseArgv::Error,
        "test: argument <option> missing - '-o'"
      )
    end
  end

  context 'when an undefined option is used' do
    let(:argv) { %w[--foo] }

    it 'raises an error' do
      expect { result }.to raise_error(
        ParseArgv::Error,
        "test: unknown option - '--foo'"
      )
    end
  end
end
