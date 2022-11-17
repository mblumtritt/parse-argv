# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:number]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      :number
    )
  end

  let(:argv) { %w[--opt 42] }

  it { is_expected.to eq 42 }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be a number - <value>'
      )
    end
  end

  context 'when a float number is given' do
    let(:argv) { %w[--opt 42.21] }

    it { is_expected.to eq 42.21 }
  end

  include_examples 'when value is not defined'

  context 'when it needs to be positive' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :number,
        :positive
      )
    end

    it { is_expected.to eq 42 }

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 0] }

      it 'raises' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a positive number - <value>'
        )
      end
    end
  end

  context 'when it needs to be negative' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :number,
        :negative
      )
    end

    let(:argv) { %w[--opt:-42] }

    it { is_expected.to eq(-42) }

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 0] }

      it 'raises' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a negative number - <value>'
        )
      end
    end
  end

  context 'when it needs to be nonzero' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :number,
        :nonzero
      )
    end

    it { is_expected.to eq 42 }

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 0] }

      it 'raises' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a nonzero number - <value>'
        )
      end
    end
  end
end
