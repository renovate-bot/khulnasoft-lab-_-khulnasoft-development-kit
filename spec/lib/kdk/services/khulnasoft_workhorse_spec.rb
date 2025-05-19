# frozen_string_literal: true

RSpec.describe KDK::Services::KhulnasoftWorkhorse do
  describe '#name' do
    it 'return khulnasoft-workhorse' do
      expect(subject.name).to eq('khulnasoft-workhorse')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run KhulnaSoft Workhorse' do
      expect(subject.command).to eq('/usr/bin/env PATH="/home/git/kdk/gitlab/workhorse:$PATH" GEO_SECONDARY_PROXY=0 ' \
        'khulnasoft-workhorse -authSocket "/home/git/kdk/gitlab.socket" ' \
        '-documentRoot "/home/git/kdk/gitlab/public" ' \
        '-developmentMode -secretPath "/home/git/kdk/gitlab/.khulnasoft_workhorse_secret" ' \
        '-config "/home/git/kdk/gitlab/workhorse/config.toml" ' \
        '-listenAddr "127.0.0.1:3333" -logFormat json ' \
        '-apiCiLongPollingDuration "0s"')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject).to be_enabled
    end
  end

  describe 'when config has relative_url_root' do
    before do
      allow(KDK.config).to receive(:relative_url_root).and_return('/gitlab')
    end

    describe '#command' do
      it 'returns the necessary command to run KhulnaSoft Workhorse' do
        expect(subject.command).to include(
          '-authBackend "http://localhost:8080/gitlab"'
        )
      end
    end
  end

  describe 'when config sets ci_long_polling_seconds' do
    before do
      config = {
        'workhorse' => {
          'ci_long_polling_seconds' => 30
        }
      }

      stub_kdk_yaml(config)
    end

    describe '#command' do
      it 'returns the necessary command to run KhulnaSoft Workhorse' do
        expect(subject.command).to include(
          '-apiCiLongPollingDuration "30s"'
        )
      end
    end
  end
end
