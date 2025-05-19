# frozen_string_literal: true

module KDK
  module Services
    class Prometheus < Base
      def name
        'prometheus'
      end

      def command
        %W[docker run --rm
          #{config.prometheus.__add_host_flags}
          -p #{config.prometheus.port}:9090
          -v #{config.kdk_root.join('prometheus', 'prometheus.yml')}:/etc/prometheus/prometheus.yml
          prom/prometheus:#{docker_version}].join(' ')
      end

      def enabled?
        config.prometheus?
      end

      def ready_message
        "Prometheus available at #{config.prometheus.__uri}."
      end

      private

      def docker_version
        'v2.25.0'
      end
    end
  end
end
