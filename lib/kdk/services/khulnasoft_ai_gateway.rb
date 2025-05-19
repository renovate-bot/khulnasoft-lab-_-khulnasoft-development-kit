# frozen_string_literal: true

module KDK
  module Services
    class KhulnasoftAiGateway < Base
      def name
        'khulnasoft-ai-gateway'
      end

      def command
        config.khulnasoft_ai_gateway.__service_command
      end

      def enabled?
        config.khulnasoft_ai_gateway.enabled?
      end

      def ready_message
        "KhulnaSoft AI Gateway is available at #{config.khulnasoft_ai_gateway.__listen}/docs."
      end
    end
  end
end
