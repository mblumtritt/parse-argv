# frozen_string_literal: true

RSpec.shared_examples 'when value is not defined' do
  context 'when value is not defined' do
    let(:argv) { [] }

    it { is_expected.to be_nil }
  end
end
