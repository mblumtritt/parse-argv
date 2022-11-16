# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion.define type' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      :mytype
    )
  end

  before do
    ParseArgv::Conversion.define(:mytype) do |arg, &err|
      arg == 'test' || err['not a custom type']
      arg
    end
  end

  let(:argv) { %w[--opt test] }

  it { is_expected.to eq 'test' }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: not a custom type - <value>'
      )
    end
  end

  include_examples 'when value is not defined'
end
