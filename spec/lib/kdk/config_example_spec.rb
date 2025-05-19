# frozen_string_literal: true

require 'kdk/config_example'

RSpec.describe KDK::ConfigExample do
  subject(:config) { described_class.new }

  describe '#kdk_root' do
    it 'returns the kdk directory in ~git' do
      expect(config.kdk_root.to_s).to eq('/home/git/kdk')
    end
  end

  describe '#username' do
    it 'returns git' do
      expect(config.username).to eq('git')
    end
  end

  describe '#praefect' do
    let(:praefect) { config.praefect }

    it 'returns a stubbed settings object' do
      expect(praefect).to be_a(KDK::ConfigExample::Settings)
    end

    describe '#database' do
      let(:database) { praefect.database }

      describe '#sslmode' do
        let(:sslmode) { database.sslmode }

        it { expect(sslmode).to eq('disable') }
      end
    end
  end

  describe '#dump!' do
    it 'does not read any file' do
      expect(File).not_to receive(:read)

      config.dump!
    end
  end

  describe '.dump_as_yaml' do
    context 'with stubbed Ruby config' do
      let(:rbconfig) { RbConfig::CONFIG.dup }
      let(:example_config) do
        Class.new(described_class) do
          string(:package_platform) { KDK::Machine.package_platform }
        end
      end

      before do
        stub_const('RbConfig::CONFIG', rbconfig)
      end

      it 'always uses linux x86_64 as RbConfig' do
        rbconfig['host_os'] = 'darwin'
        rbconfig['target_cpu'] = 'arm64'

        yaml = example_config.dump_as_yaml

        expect(yaml).to eq(<<~YAML)
          ---
          package_platform: linux-amd64
        YAML
      end
    end
  end
end
