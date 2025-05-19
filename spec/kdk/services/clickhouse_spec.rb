# frozen_string_literal: true

RSpec.describe KDK::Services::Clickhouse do
  describe '#name' do
    it 'returns clickhouse' do
      expect(subject.name).to eq('clickhouse')
    end
  end

  describe '#command' do
    before do
      config = {
        'clickhouse' => {
          'bin' => '/tmp/clickhouse-bin',
          'dir' => '/tmp/clickhouse'
        }
      }

      stub_kdk_yaml(config)
    end

    it 'returns command based on configured values' do
      expect(subject.command).to eq("/tmp/clickhouse-bin server --config-file=/tmp/clickhouse/config.xml")
    end
  end

  describe '#enabled?' do
    it 'returns true if set `enabled: true` in the config file' do
      config = {
        'clickhouse' => {
          'enabled' => true
        }
      }

      stub_kdk_yaml(config)

      expect(subject.enabled?).to be(true)
    end

    it 'returns false if set `enabled: false` in the config file' do
      config = {
        'clickhouse' => {
          'enabled' => false
        }
      }

      stub_kdk_yaml(config)

      expect(subject.enabled?).to be(false)
    end
  end
end
