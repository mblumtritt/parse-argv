# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:array]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(:array)
  end

  let(:argv) { ['--opt', '[aaaa,  bbb,cc  ,,d]'] }

  it { is_expected.to eq %w[aaaa bbb cc d] }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt []] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument can not be empty - <value>'
      )
    end
  end

  include_examples 'when value is not defined'
end
