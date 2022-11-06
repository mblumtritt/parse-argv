# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[[<type>]]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as([:integer], :value, :positive) }
  let(:argv) { %w[--opt [1,2,3]] }

  it 'returns the correct value' do
    expect(value).to eq [1, 2, 3]
  end

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt [1,2,-3]] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: positive integer number expected - <value>'
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
