# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Pguser do
  describe '#success?' do
    context 'when PGUSER env var is set' do
      before do
        allow(ENV).to receive(:has_key?).with('PGUSER').and_return(true)
      end

      it 'returns false' do
        expect(subject).not_to be_success
      end
    end

    context 'when PGUSER env var is not set' do
      before do
        allow(ENV).to receive(:has_key?).with('PGUSER').and_return(false)
      end

      it 'returns true' do
        expect(subject).to be_success
      end
    end
  end

  describe '#detail' do
    context 'when successful' do
      before do
        allow(subject).to receive(:success?).and_return(true)
      end

      it 'returns nil' do
        expect(subject.detail).to be_nil
      end
    end

    context 'when unsuccessful' do
      before do
        allow(subject).to receive(:success?).and_return(false)
      end

      it 'returns help message' do
        expected = <<~MESSAGE
          The PGUSER environment variable is set and may cause issues with
          underlying postgresql commands ran by KDK.
        MESSAGE

        expect(subject.detail).to eq(expected)
      end
    end
  end
end
