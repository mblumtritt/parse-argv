# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[/.../]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(/\Ate+st\z/, :value) }
  let(:argv) { %w[--opt teeeeest] }

  it 'returns the correct value' do
    expect(value).to eq 'teeeeest'
  end

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt toest] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must match (?-mix:\Ate+st\z) - <value>'
      )
    end
  end

  context 'when value is not defined' do
    let(:argv) { [] }

    it 'returns nil' do
      expect(value).to be_nil
    end
  end

  context 'when the :match option is given' do
    let(:value) { result.as(/\At(e+)st\z/, :value, :match) }

    it 'returns the Regexp::Match' do
      expect(value).to eq(/\At(e+)st\z/.match('teeeeest'))
    end
  end
end
