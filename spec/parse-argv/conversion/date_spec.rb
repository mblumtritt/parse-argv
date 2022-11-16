# frozen_string_literal: true

require 'date'
require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:date]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(:date)
  end

  let(:argv) { %w[--opt 2022-01-02] }

  it { is_expected.to eq Date.new(2022, 1, 2) }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be a date - <value>'
      )
    end
  end

  include_examples 'when value is not defined'

  today = Date.today
  {
    '0131' => Date.new(today.year, 1, 31),
    '20220131' => Date.new(2022, 1, 31),
    '17' => Date.new(today.year, today.month, 17),
    'may-12' => Date.new(today.year, 5, 12),
    '1.april' => Date.new(today.year, 4, 1)
  }.each_pair do |arg, expected|
    context "when a shorthand Date is given like '#{arg}'" do
      let(:argv) { ['--opt', arg] }

      it { is_expected.to eq expected }
    end
  end

  context 'when a reference date is given' do
    subject(:value) do
      ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
        :date,
        reference: Date.new(2000, 9)
      )
    end

    let(:argv) { %w[--opt 17] }

    it { is_expected.to eq Date.new(2000, 9, 17) }
  end
end
