# frozen_string_literal: true

require_relative '../../helper'

RSpec.describe 'Conversion[:regexp]' do
  subject(:result) { ParseArgv.from("usage: test:\n --opt <value> some", argv) }

  let(:value) { result.as(:regexp, :value) }
  let(:argv) { %w[--opt \Atest.*] }

  it 'returns the correct value' do
    expect(value).to eq(/\Atest.*/)
  end

  context 'when an invalid value is given' do
    let(:argv) { ['--opt', '/some[/'] }

    it 'raises an error' do
      expect { value }.to raise_error(
        ParseArgv::Error,
        'test: invalid regular expression; ' \
          'premature end of char-class: /some[/ - <value>'
      )
    end
  end

  context 'when value is not defined' do
    let(:argv) { [] }

    it 'returns nil' do
      expect(value).to be_nil
    end
  end
end
