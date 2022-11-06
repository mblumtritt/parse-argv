# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[:float]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(:float, :value) }
  let(:argv) { %w[--opt 42.21.21] }

  it 'returns the correct value' do
    expect(value).to eq 42.21
  end

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument have to be a float number - <value>'
      )
    end
  end

  context 'when value is not defined' do
    let(:argv) { [] }

    it 'returns nil' do
      expect(value).to be_nil
    end

    context 'when a default is specified' do
      it 'returns the default value' do
        expect(result.as(:float, :value, default: 21)).to eq 21
      end
    end
  end

  context 'when it needs to be positive' do
    let(:value) { result.as(:float, :value, :positive) }

    it 'returns the correct value' do
      expect(value).to eq 42.21
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 0] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: positive float number expected - <value>'
        )
      end
    end
  end

  context 'when it needs to be negative' do
    let(:value) { result.as(:float, :value, :negative) }
    let(:argv) { %w[--opt:-42.21] }

    it 'returns the correct value' do
      expect(value).to eq(-42.21)
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 0] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: negative float number expected - <value>'
        )
      end
    end
  end

  context 'when it needs to be nonzero' do
    let(:value) { result.as(:float, :value, :nonzero) }

    it 'returns the correct value' do
      expect(value).to eq 42.21
    end

    context 'when an invalid value is given' do
      let(:argv) { %w[--opt 0] }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: nonzero float number expected - <value>'
        )
      end
    end
  end
end
