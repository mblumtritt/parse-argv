# frozen_string_literal: true

require 'date'
require_relative '../../helper'

RSpec.describe 'Conversion[:date]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(:date, :value) }
  let(:argv) { %w[--opt 2022-01-02] }

  it 'returns the correct value' do
    expect(value).to eq Date.new(2022, 1, 2)
  end

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be a date - <value>'
      )
    end
  end

  context 'when value is not defined' do
    let(:argv) { [] }

    it 'returns nil' do
      expect(value).to be_nil
    end
  end

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

      it "converts to a Date: #{expected}" do
        expect(value).to eq expected
      end
    end
  end

  context 'when a reference date is given' do
    let(:argv) { %w[--opt 17] }

    it 'uses the reference to complete the result' do
      expect(result.as(:date, :value, reference: Date.new(2000, 9))).to eq(
        Date.new(2000, 9, 17)
      )
    end
  end
end
