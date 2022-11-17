# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:integer]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      :integer
    )
  end

  let(:argv) { %w[--opt 42] }

  it { is_expected.to eq 42 }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be an integer - <value>'
      )
    end
  end

  include_examples 'when value is not defined'

  context 'when it needs to be positive' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :integer,
        :positive
      )
    end

    it { is_expected.to eq 42 }

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 0] }

      it 'raises' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a positive integer - <value>'
        )
      end
    end
  end

  context 'when it needs to be negative' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :integer,
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
          'test: argument must be a negative integer - <value>'
        )
      end
    end
  end

  context 'when it needs to be nonzero' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :integer,
        :nonzero
      )
    end

    it { is_expected.to eq 42 }

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 0] }

      it 'raises' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: argument must be a nonzero integer - <value>'
        )
      end
    end
  end
end
