# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[:file_name]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(:file_name, :value) }
  let(:argv) { %w[--opt file.ext] }

  it 'returns the correct value' do
    expect(value).to eq File.join(Dir.pwd, 'file.ext')
  end

  context 'when an invalid value is given' do
    let(:argv) { ['--opt', ''] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument can not be empty - <value>'
      )
    end
  end

  context 'when value is not defined' do
    let(:argv) { [] }

    it 'returns nil' do
      expect(value).to be_nil
    end
  end

  context 'when relative directory name is specified' do
    let(:value) { result.as(:file_name, :value, rel: '..') }

    it 'returns the correct value' do
      expect(value).to eq File.expand_path('../file.ext', Dir.pwd)
    end
  end
end
