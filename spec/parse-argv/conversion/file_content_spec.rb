# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:file_content]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      :file_content
    )
  end

  let(:argv) { ['--opt', __FILE__] }

  it { is_expected.to eq File.read(__FILE__) }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: file does not exist - <value>'
      )
    end
  end

  context 'when not a file is given' do
    let(:argv) { ['--opt', __dir__] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be a file - <value>'
      )
    end
  end

  include_examples 'when value is not defined'

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
