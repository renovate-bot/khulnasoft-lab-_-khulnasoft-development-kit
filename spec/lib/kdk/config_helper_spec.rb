# frozen_string_literal: true

RSpec.describe KDK::ConfigHelper do
  let(:kdk_root) { Pathname.new('/home/git/kdk') }
  let(:config) { instance_double(KDK::Config, kdk_root: kdk_root) }
  let(:version_path) { 'VERSION' }
  let(:full_path) { kdk_root.join(version_path) }

  before do
    allow(kdk_root).to receive(:join).with(version_path).and_return(full_path)
  end

  describe '.version_from' do
    context 'when version file exists' do
      before do
        allow(full_path).to receive(:exist?).and_return(true)
      end

      context 'when version file contains a commit hash' do
        it 'returns the commit hash' do
          commit_hash = 'a' * 40
          allow(full_path).to receive(:read).and_return(commit_hash)
          expect(described_class.version_from(config, version_path)).to eq(commit_hash)
        end
      end

      context 'when version file contains a short version' do
        it 'returns the version prefixed with v' do
          allow(full_path).to receive(:read).and_return("1.2.3\n")
          expect(described_class.version_from(config, version_path)).to eq('v1.2.3')
        end
      end
    end

    context 'when version file does not exist' do
      before do
        allow(full_path).to receive(:exist?).and_return(false)
      end

      it 'returns an empty string' do
        expect(described_class.version_from(config, version_path)).to eq('')
      end
    end
  end
end
