# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:directory]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      :directory
    )
  end

  let(:argv) { ['--opt', __dir__] }

  it { is_expected.to eq __dir__ }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: directory does not exist - <value>'
      )
    end
  end

  context 'when not a file is given' do
    let(:argv) { ['--opt', __FILE__] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be a directory - <value>'
      )
    end
  end

  include_examples 'when value is not defined'

  context 'when an additional file attribute is given' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :directory,
        :readable
      )
    end

    it { is_expected.to eq __dir__ }

    context 'when the attribute is not valid for the directory' do
      subject(:value) do
        ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
          :directory,
          :symlink
        )
      end

      it 'raises' do
        expect { value }.to raise_error(
          ParseArgv::Error,
          'test: directory is not symlink - <value>'
        )
      end
    end
  end
end
