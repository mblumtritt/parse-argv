# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[:file]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(:file, :value) }
  let(:argv) { ['--opt', __FILE__] }

  it 'returns the correct value' do
    expect(value).to eq __FILE__
  end

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: file does not exist - <value>'
      )
    end
  end

  context 'when not a file is given' do
    let(:argv) { ['--opt', __dir__] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be a file - <value>'
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
    let(:value) { result.as(:file, :value, :readable) }

    it 'returns the correct value' do
      expect(value).to eq __FILE__
    end

    context 'when the attribute is not valid for the file' do
      let(:value) { result.as(:file, :value, :symlink) }

      it 'raises an error' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: file is not symlink - <value>'
        )
      end
    end
  end
end
