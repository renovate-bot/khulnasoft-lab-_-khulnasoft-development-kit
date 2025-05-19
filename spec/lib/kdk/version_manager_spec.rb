# frozen_string_literal: true

require_relative '../../../lib/kdk/version_manager'

RSpec.describe KDK::VersionManager do
  let(:gitaly_version_file) { '/home/git/kdk/khulnasoft/GITALY_SERVER_VERSION' }
  let(:khulnasoft_shell_version_file) { '/home/git/kdk/khulnasoft/KHULNASOFT_SHELL_VERSION' }
  let(:khulnasoft_workhorse_version_file) { '/home/git/kdk/khulnasoft/KHULNASOFT_WORKHORSE_VERSION' }

  before do
    allow(KDK.config.kdk_root).to receive(:join).with('khulnasoft', 'GITALY_SERVER_VERSION').and_return(gitaly_version_file)
    allow(KDK.config.kdk_root).to receive(:join).with('khulnasoft', 'KHULNASOFT_SHELL_VERSION').and_return(khulnasoft_shell_version_file)
    allow(KDK.config.kdk_root).to receive(:join).with('khulnasoft', 'KHULNASOFT_WORKHORSE_VERSION').and_return(khulnasoft_workhorse_version_file)
  end

  describe '.fetch' do
    context 'when version file exists' do
      it 'returns the version for Gitaly' do
        allow(File).to receive(:exist?).with(gitaly_version_file).and_return(true)
        allow(File).to receive(:read).with(gitaly_version_file).and_return("75281001cbb0339ff4467b1a1ba8f9390af95a7b\n")

        version = described_class.fetch(:gitaly)
        expect(version).to eq('75281001cbb0339ff4467b1a1ba8f9390af95a7b')
      end

      it 'returns the version for KhulnaSoft Shell' do
        allow(File).to receive(:exist?).with(khulnasoft_shell_version_file).and_return(true)
        allow(File).to receive(:read).with(khulnasoft_shell_version_file).and_return("14.42.0\n")

        version = described_class.fetch(:khulnasoft_shell)
        expect(version).to eq('14.42.0')
      end

      it 'returns the version for KhulnaSoft Workhorse' do
        allow(File).to receive(:exist?).with(khulnasoft_workhorse_version_file).and_return(true)
        allow(File).to receive(:read).with(khulnasoft_workhorse_version_file).and_return("18.0.0-pre\n")

        version = described_class.fetch(:workhorse)
        expect(version).to eq('18.0.0-pre')
      end
    end

    context 'when version file does not exist' do
      it 'falls back to "main" for Gitaly' do
        allow(File).to receive(:exist?).with(gitaly_version_file).and_return(false)

        version = described_class.fetch(:gitaly)
        expect(version).to eq('main')
      end

      it 'falls back to "main" for KhulnaSoft Shell' do
        allow(File).to receive(:exist?).with(khulnasoft_shell_version_file).and_return(false)

        version = described_class.fetch(:khulnasoft_shell)
        expect(version).to eq('main')
      end

      it 'falls back to "main" for KhulnaSoft Workhorse' do
        allow(File).to receive(:exist?).with(khulnasoft_workhorse_version_file).and_return(false)

        version = described_class.fetch(:workhorse)
        expect(version).to eq('main')
      end
    end

    context 'when graphql_schema is fetched' do
      it 'always returns "master"' do
        expect(File).not_to receive(:exist?)
        expect(File).not_to receive(:read)

        version = described_class.fetch(:graphql_schema)
        expect(version).to eq('master')
      end
    end

    context 'when package is unknown' do
      it 'falls back to "main"' do
        version = described_class.fetch(:unknown_package)
        expect(version).to eq('main')
      end
    end
  end
end
