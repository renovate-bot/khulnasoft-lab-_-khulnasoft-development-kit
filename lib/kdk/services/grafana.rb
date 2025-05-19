# frozen_string_literal: true

module KDK
  module Services
    class Grafana < Base
      def name
        'grafana'
      end

      def command
        'support/exec-cd grafana grafana/bin/grafana-server -homepath grafana -config grafana.ini'
      end

      def ready_message
        "Grafana available at #{config.grafana.__uri}."
      end

      def enabled?
        config.grafana?
      end
    end
  end
end
