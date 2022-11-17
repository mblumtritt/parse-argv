# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:file_name]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      :file_name
    )
  end

  let(:argv) { %w[--opt file.ext] }

  it { is_expected.to eq File.join(Dir.pwd, 'file.ext') }

  context 'when an invalid value is given' do
    let(:argv) { ['--opt', ''] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be not empty - <value>'
      )
    end
  end



  context 'when relative directory name is specified' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :file_name,
        rel: '..'
      )
    end

    it 'returns the correct value' do
      expect(value).to eq File.expand_path('../file.ext', Dir.pwd)
    end
  end
end
