# frozen_string_literal: true

RSpec.describe KDK::Command::TruncateLegacyTables do
  subject(:truncate_legacy_tables) { described_class.new }

  describe '#run' do
    context 'when truncation is needed' do
      before do
        allow(truncate_legacy_tables).to receive(:truncation_needed?).and_return(true)
      end

      it 'executes truncation' do
        expect(truncate_legacy_tables).to receive(:ensure_databases_running)
        expect(truncate_legacy_tables).to receive(:truncate_tables)
        expect(truncate_legacy_tables.run).to be true
      end
    end

    context 'when truncation is not needed' do
      before do
        allow(truncate_legacy_tables).to receive(:truncation_needed?).and_return(false)
      end

      it 'does nothing and return true' do
        expect(KDK::Output).to receive(:info).with('Truncation not required as your KDK is up-to-date.')
        expect(truncate_legacy_tables).not_to receive(:ensure_databases_running)
        expect(truncate_legacy_tables).not_to receive(:truncate_tables)
        expect(truncate_legacy_tables.run).to be true
      end
    end
  end

  describe '#truncation_needed?' do
    let(:ci_enabled) { true }
    let(:geo_secondary) { false }
    let(:flag_file_exists) { false }

    before do
      allow(KDK.config).to receive_message_chain(:khulnasoft, :rails, :databases, :ci, :enabled).and_return(ci_enabled)
      allow(KDK.config).to receive_message_chain(:geo, :secondary?).and_return(geo_secondary)
      allow(File).to receive(:exist?).with(described_class::FLAG_FILE).and_return(flag_file_exists)
    end

    context 'when CI database is enabled, not a Geo secondary, and flag file does not exist' do
      it 'returns true' do
        expect(truncate_legacy_tables.truncation_needed?).to be true
      end
    end

    context 'when CI database is disabled' do
      let(:ci_enabled) { false }

      it 'returns false' do
        expect(truncate_legacy_tables.truncation_needed?).to be false
      end
    end

    context 'when it is a Geo secondary' do
      let(:geo_secondary) { true }

      it 'returns false' do
        expect(truncate_legacy_tables.truncation_needed?).to be false
      end
    end

    context 'when flag file exists' do
      let(:flag_file_exists) { true }

      it 'returns false' do
        expect(truncate_legacy_tables.truncation_needed?).to be false
      end
    end
  end
end
