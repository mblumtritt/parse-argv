# frozen_string_literal: true

require_relative '../helper'

RSpec.describe 'simple command parsing' do
  subject(:result) { ParseArgv.from(help_text, argv) }
  let(:help_text) { Fixture['simple'] }

  context 'when a required argument is missing' do
    let(:argv) { %w[] }

    it 'raises an ParseArgv::Error' do
      expect { result }.to raise_error(
        ParseArgv::Error,
        'simple: argument missing - <input>'
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
        'simple: too many arguments'
      )
    end
  end

  context 'when only required <input> is given' do
    let(:argv) { %w[input_arg] }

    context 'attribute existence' do
      it 'confirms if an attribute exists' do
        expect(result.respond_to?('switch')).to be true
        expect(result.respond_to?(:next)).to be true
        expect(result.respond_to?(:n)).to be true
        expect(result.respond_to?(:help)).to be true
        expect(result.respond_to?(:version)).to be true
        expect(result.respond_to?(:input)).to be true
      end

      it 'does not confirm if an attribute does not exist' do
        expect(result.respond_to?('option')).to be false
        expect(result.respond_to?(:prefix)).to be false
        expect(result.respond_to?(:pref)).to be false
        expect(result.respond_to?(:output)).to be false
        expect(result.respond_to?(:foo)).to be false
      end
    end

    context 'attributes' do
      it 'has correct command name' do
        expect(result.command_name).to eq 'simple'
      end

      it 'has related help text' do
        expect(result.help_text).to eq help_text.chomp
      end

      it 'defines custom attributes' do
        expect(result.input).to eq 'input_arg'
        expect(result.switch?).to be false
      end
    end

    it 'can be converted to Hash' do
      expect(result.to_h).to eq(
        input: 'input_arg',
        switch: false,
        next: false,
        n: false,
        help: false,
        version: false
      )
    end
  end

  context 'when all standard options are configured' do
    let(:argv) do
      %w[
        -s
        --next
        -n
        --opt
        option_arg
        --pref
        prefix_arg
        -p
        pref_arg
        input_arg
        output_arg
      ]
    end

    it 'parses all attributes correctly' do
      expect(result.to_h).to eq(
        input: 'input_arg',
        output: 'output_arg',
        switch: true,
        next: true,
        n: true,
        option: 'option_arg',
        prefix: 'prefix_arg',
        pref: 'pref_arg',
        help: false,
        version: false
      )
    end
  end

  context 'when short hand options are used' do
    let(:argv) { %w[-snop option_arg pref_arg input_arg output_arg] }

    it 'allows to condense the options' do
      expect(result.to_h).to eq(
        input: 'input_arg',
        output: 'output_arg',
        switch: true,
        next: false,
        n: true,
        option: 'option_arg',
        pref: 'pref_arg',
        help: false,
        version: false
      )
    end
  end

  context 'when alternative option value assignment is used' do
    let(:argv) do
      %w[-s:true --next:on -n:t -o:option_arg --pref:prefix_arg input_arg]
    end

    it 'allows to use alternative option value assignment' do
      expect(result.to_h).to eq(
        input: 'input_arg',
        switch: true,
        next: true,
        n: true,
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
        "simple: argument <option> missing - '-o'"
      )
    end
  end
end
