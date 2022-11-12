# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[:file_content]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(:file_content, :value) }
  let(:argv) { ['--opt', __FILE__] }

  it 'returns the correct value' do
    expect(value).to eq File.read(__FILE__)
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

  context 'when value is "-"' do
    let(:argv) { %w[--opt:-] }

    it 'reads from $stdin' do
      expect($stdin).to receive(:read)
      value
    end

    it 'returns all read from $stdin' do
      allow($stdin).to receive(:read).and_return(:std_result)
      expect(value).to be :std_result
    end
  end
end
