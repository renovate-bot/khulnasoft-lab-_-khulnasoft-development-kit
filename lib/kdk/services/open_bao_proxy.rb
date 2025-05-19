# frozen_string_literal: true

module KDK
  module Services
    class OpenBaoProxy < Base
      def name
        'openbao-proxy'
      end

      def command
        config.openbao.vault_proxy.__server_command
      end

      def enabled?
        config.openbao.vault_proxy.enabled
      end

      def ready_message
        "OpenBaoProxy is available at #{listen_address}."
      end

      private

      def listen_address
        URI::HTTP.build(host: config.hostname, port: config.openbao.vault_proxy.port)
      end
    end
  end
end
