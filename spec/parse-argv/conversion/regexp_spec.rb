# frozen_string_literal: true

require_relative '../../helper'
require_relative 'shared'

RSpec.describe 'Conversion[:regexp]' do
  subject(:value) do
    ParseArgv.from("usage: test:\n --opt <value> some", argv)[:value].as(
      :regexp
    )
  end

  let(:argv) { %w[--opt \Atest.*] }

  it { is_expected.to eq(/\Atest.*/) }

  context 'when an invalid value is given' do
    let(:argv) { ['--opt', '/some[/'] }

    it 'raises' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: invalid regular expression; ' \
          'premature end of char-class: /some[/ - <value>'
      )
    end
  end

  include_examples 'when value is not defined'
end
