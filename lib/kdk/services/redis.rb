# frozen_string_literal: true

module KDK
  module Services
    # Redis server
    class Redis < Base
      def name
        'redis'
      end

      def command
        %(redis-server #{redis_config})
      end

      def enabled?
        config.redis.enabled?
      end

      private

      def redis_config
        config.redis.dir.join('redis.conf')
      end
    end
  end
end
