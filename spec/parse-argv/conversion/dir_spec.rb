# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[:directory]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(:directory, :value) }
  let(:argv) { ['--opt', __dir__] }

  it 'returns the correct value' do
    expect(value).to eq __dir__
  end

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: directory does not exist - <value>'
      )
    end
  end

  context 'when not a file is given' do
    let(:argv) { ['--opt', __FILE__] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be a directory - <value>'
      )
    end
  end

  context 'when value is not defined' do
    let(:argv) { [] }

    it 'returns nil' do
      expect(value).to be_nil
    end
  end

  context 'when an additional file attribute is given' do
    let(:value) { result.as(:directory, :value, :readable) }

    it 'returns the correct value' do
      expect(value).to eq __dir__
    end

    context 'when the attribute is not valid for the directory' do
      let(:value) { result.as(:directory, :value, :symlink) }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: directory is not symlink - <value>'
        )
      end
    end
  end
end
