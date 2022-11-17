# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[Array<String>]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      %w[one two three]
    )
  end

  let(:argv) { %w[--opt two] }

  it { is_expected.to eq 'two' }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be one of [`one`, `two`, `three`] - <value>'
      )
    end
  end

  context 'when value is not defined' do
    let(:argv) { [] }

    it { is_expected.to be_nil }

    context 'when a default is specified' do
      subject(:value) do
        ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
          %w[one two three],
          default: 'seven'
        )
      end

      it { is_expected.to eq 'seven' }
    end
  end
end
