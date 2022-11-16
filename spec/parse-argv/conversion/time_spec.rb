# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:time]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(:time)
  end

  let(:argv) { ['--opt', '2022-01-02 13:14:15 GMT'] }

  it { is_expected.to eq Time.new(2022, 1, 2, 13, 14, 15, 0) }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be a time - <value>'
      )
    end
  end

  include_examples 'when value is not defined'

  now = Time.now
  {
    '0131' => Time.new(now.year, 1, 31, 0, 0, 0, now.utc_offset),
    '13:14' => Time.new(now.year, now.month, now.mday, 13, 14),
    '13:14 utc+2' => Time.new(now.year, now.month, now.mday, 13, 14, 0, 7200),
    '17 13:14' => Time.new(now.year, now.month, 17, 13, 14),
    'may-12 13:14' => Time.new(now.year, 5, 12, 13, 14)
  }.each_pair do |arg, expected|
    context "when a shorthand Time is given like '#{arg}'" do
      let(:argv) { ['--opt', arg] }

      it { is_expected.to eq expected }
    end
  end

  context 'when a reference date is given' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :time,
        reference: Time.new(2000, 9, 8)
      )
    end

    let(:argv) { %w[--opt 13:14] }

    it { is_expected.to eq Time.new(2000, 9, 8, 13, 14) }
  end
end
