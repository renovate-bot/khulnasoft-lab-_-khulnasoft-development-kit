# frozen_string_literal: true

module KDK
  module Services
    class OpenBao < Base
      def name
        'openbao'
      end

      def command
        config.openbao.__server_command
      end

      def enabled?
        config.openbao.enabled
      end

      def ready_message
        "OpenBao is available at #{listen_address}."
      end

      private

      def listen_address
        klass = config.https? ? URI::HTTPS : URI::HTTP

        klass.build(host: config.hostname, port: config.openbao.port)
      end
    end
  end
end
