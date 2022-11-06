# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[Array<String>]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(%w[one two three], :value) }
  let(:argv) { %w[--opt two] }

  it 'returns the correct value' do
    expect(value).to eq 'two'
  end

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be one of `one`, `two`, `three` - <value>'
      )
    end
  end

  context 'when value is not defined' do
    let(:argv) { [] }

    it 'returns nil' do
      expect(value).to be_nil
    end

    context 'when a default is specified' do
      let(:value) { result.as(%w[one two three], :value, default: 'seven') }

      it 'returns the default value' do
        expect(value).to eq 'seven'
      end
    end
  end
end
