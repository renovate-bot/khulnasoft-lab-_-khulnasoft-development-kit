# frozen_string_literal: true

module KDK
  module Services
    # Redis server in cluster mode
    class RedisCluster < Base
      def name
        'redis-cluster'
      end

      def command
        %(support/redis-cluster-signal-wrapper #{redis_config_dir} #{hostname} #{dev_ports} #{test_ports})
      end

      def enabled?
        config.redis_cluster.enabled
      end

      private

      def redis_config_dir
        config.redis_cluster.dir
      end

      def hostname
        config.hostname
      end

      def dev_ports
        [
          config.redis_cluster.dev_port_1,
          config.redis_cluster.dev_port_2,
          config.redis_cluster.dev_port_3
        ].join(':')
      end

      def test_ports
        [
          config.redis_cluster.test_port_1,
          config.redis_cluster.test_port_2,
          config.redis_cluster.test_port_3
        ].join(':')
      end
    end
  end
end
