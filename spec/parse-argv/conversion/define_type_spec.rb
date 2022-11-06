# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion.define type' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  before do
    ParseArgv::Conversion.define(:my) do |arg, &err|
      arg == 'test' || err['not a custom type']
      arg
    end
  end

  let(:value) { result.as(:my, :value) }
  let(:argv) { %w[--opt test] }

  it 'returns the correct value' do
    expect(value).to eq 'test'
  end

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: not a custom type - <value>'
      )
    end
  end

  context 'when value is not defined' do
    let(:argv) { [] }

    it 'returns nil' do
      expect(value).to be_nil
    end
  end
end
