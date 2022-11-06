# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[:array]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(:array, :value) }
  let(:argv) { ['--opt', '[aaaa,  bbb,cc  ,,d]'] }

  it 'returns the correct value' do
    expect(value).to eq %w[aaaa bbb cc d]
  end

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt []] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument can not be empty - <value>'
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
