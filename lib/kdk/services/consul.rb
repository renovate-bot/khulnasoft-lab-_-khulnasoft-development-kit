# frozen_string_literal: true

module KDK
  module Services
    class Consul < Base
      def name
        'consul'
      end

      def command
        "consul agent -config-file #{config.kdk_root.join('consul/config.json')} -dev"
      end

      def env
        { 'PGPASSWORD' => 'khulnasoft' }
      end

      def enabled?
        config.load_balancing.discover?
      end
    end
  end
end
