# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Diagnostic::Uptime do
  include ShelloutHelper

  subject(:diagnostic) { described_class.new }

  before do
    allow(KDK::Machine).to receive(:uptime) { uptime }
  end

  context 'when uptime is less than 24 hours' do
    let(:uptime) { 5.33 * 60 * 60 }

    describe '#success?' do
      it { expect(diagnostic.success?).to be(true) }
    end

    describe '#detail' do
      it { expect(diagnostic.detail).to be_nil }
    end
  end

  context 'when uptime is more than 24 hours' do
    let(:uptime) { 26.05 * 60 * 60 }

    describe '#success?' do
      it 'returns false' do
        expect(diagnostic.success?).to be(false)
      end
    end

    describe '#detail' do
      it 'returns a warning message' do
        expect(diagnostic.detail).to eq <<~MESSAGE
          Your machine has been up for 26 hours.

          We highly recommended that you reboot your machine if you are encountering
          issues with KDK and it has been up for more than 24 hours.
        MESSAGE
      end
    end
  end

  context 'when uptime helper returns nil' do
    let(:uptime) { nil }

    describe '#success?' do
      it 'returns true' do
        expect(diagnostic.success?).to be(true)
      end
    end

    describe '#detail' do
      it 'returns nil' do
        expect(diagnostic.detail).to be_nil
      end
    end
  end
end
