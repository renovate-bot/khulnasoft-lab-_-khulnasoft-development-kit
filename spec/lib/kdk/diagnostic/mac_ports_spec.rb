# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::MacPorts do
  describe '#success?' do
    context 'when MacPorts is installed' do
      before do
        allow(File).to receive(:exist?).with(described_class::MAC_PORTS_BIN).and_return(true)
      end

      it 'returns false' do
        expect(subject.success?).to be_falsey
      end
    end

    context 'when MacPorts is not installed' do
      before do
        allow(File).to receive(:exist?).with(described_class::MAC_PORTS_BIN).and_return(false)
      end

      it 'returns true' do
        expect(subject.success?).to be_truthy
      end
    end
  end

  describe '#detail' do
    context 'when #success? == true' do
      before do
        allow(subject).to receive(:success?).and_return(true)
      end

      it 'includes important path and links' do
        expect(subject.detail).to be_nil
      end
    end

    context 'when #success? == false' do
      before do
        allow(subject).to receive(:success?).and_return(false)
      end

      it 'includes important path and links' do
        expect(subject.detail).to include(described_class::MAC_PORTS_BIN, described_class::POSTGRESQL_COMPILATION_PROBLEM_ISSUE)
      end
    end
  end
end
