# frozen_string_literal: true

module KDK
  module Services
    class KhulnasoftK8sAgent < Base
      def name
        'khulnasoft-k8s-agent'
      end

      def command
        %(#{config.khulnasoft_k8s_agent.__command} --configuration-file '#{config.khulnasoft_k8s_agent.__config_file}')
      end

      def env
        { 'OWN_PRIVATE_API_URL' => config.khulnasoft_k8s_agent.__private_api_url }
      end

      def ready_message
        <<~MESSAGE
          KhulnaSoft Agent Server (KAS) available at #{config.khulnasoft_k8s_agent.__url_for_agentk}.
          Kubernetes proxy (via KAS) available at #{config.khulnasoft_k8s_agent.__k8s_api_url}.
        MESSAGE
      end

      def enabled?
        config.khulnasoft_k8s_agent? && !config.khulnasoft_k8s_agent.configure_only
      end
    end
  end
end
