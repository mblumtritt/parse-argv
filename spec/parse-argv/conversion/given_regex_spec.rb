# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[/.../]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      /\Ate+st\z/
    )
  end

  let(:argv) { %w[--opt teeeeest] }

  it { is_expected.to eq 'teeeeest' }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt toest] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must match (?-mix:\Ate+st\z) - <value>'
      )
    end
  end

  include_examples 'when value is not defined'

  context 'when the :match option is given' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        /\At(e+)st\z/,
        :match
      )
    end

    it { is_expected.to eq(/\At(e+)st\z/.match('teeeeest')) }
  end
end
