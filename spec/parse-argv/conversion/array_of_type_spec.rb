# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[[<type>]]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      [:integer],
      :positive
    )
  end

  let(:argv) { %w[--opt [1,2,3]] }

  it { is_expected.to eq [1, 2, 3] }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt [1,2,-3]] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: positive integer number expected - <value>'
      )
    end
  end

  include_examples 'when value is not defined'
end
