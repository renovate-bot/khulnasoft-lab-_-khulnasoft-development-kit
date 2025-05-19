# frozen_string_literal: true

RSpec.describe KDK::Services::RedisCluster do
  describe '#name' do
    it 'return redis' do
      expect(subject.name).to eq('redis-cluster')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run redis cluster' do
      expect(subject.command).to eq('support/redis-cluster-signal-wrapper /home/git/kdk/redis-cluster 127.0.0.1 6000:6001:6002 6003:6004:6005')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject.enabled?).to be(false)
    end

    context 'when yml is set to true' do
      before do
        config = {
          'redis_cluster' => {
            'enabled' => true
          }
        }

        stub_kdk_yaml(config)
      end

      it 'is disabled' do
        expect(subject.enabled?).to be(true)
      end
    end

    context 'when yml is set to false' do
      before do
        config = {
          'redis_cluster' => {
            'enabled' => false
          }
        }

        stub_kdk_yaml(config)
      end

      it 'is disabled' do
        expect(subject.enabled?).to be(false)
      end
    end
  end
end
