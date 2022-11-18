# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:byte]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(:byte)
  end

  let(:argv) { %w[--opt 42] }

  it { is_expected.to eq 42 }

  context 'when an invalid value is given' do
    let(:argv) { %w[--opt invalid] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: argument must be a byte number - <value>'
      )
    end
  end

  include_examples 'when value is not defined'

  {
    'kByte' => 43_223,
    'MByte' => 44_260_392,
    'GByte' => 45_322_642_391,
    'TByte' => 46_410_385_808_424,
    'PByte' => 47_524_235_067_827_160,
    'EByte' => 48_664_816_709_455_011_840,
    'ZByte' => 49_832_772_310_481_932_124_160,
    'YByte' => 51_028_758_845_933_498_495_139_840
  }.each_pair do |unit, exp|
    context "when the unit #{unit} is given" do
      let(:argv) { ['--opt', "42.21#{unit}"] }

      it { is_expected.to eq exp }
    end
  end
end
