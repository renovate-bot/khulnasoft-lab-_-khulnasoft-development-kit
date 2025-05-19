# frozen_string_literal: true

RSpec.describe KDK::Dependencies::KhulnasoftVersions do
  describe '#ruby_version' do
    before do
      actual_root = File.join(File.dirname(__FILE__), '..', '..', '..', '..')
      allow(subject).to receive(:khulnasoft_root).and_return(actual_root)
    end

    it 'returns version from local file when present' do
      expect(subject.ruby_version).to match(/[2-3]\.[0-9]/)
    end

    context 'with remote file' do
      before do
        stub_request(:get, "https://gitlab.com/gitlab-org/gitlab/-/raw/master/.ruby-version")
          .to_return(status: 200, body: '3.2.4')
      end

      it 'returns version from remote file when local is empty' do
        allow(subject).to receive(:local_ruby_version).and_return(false)

        expect(subject.ruby_version).to match(/[2-3]\.[0-9]/)
      end
    end

    it 'raises exception when bogus version content is returned' do
      allow(subject).to receive(:local_ruby_version).and_return('bugous content')

      expect { subject.ruby_version }.to raise_error(KDK::Dependencies::KhulnasoftVersions::VersionNotDetected)
    end
  end
end
