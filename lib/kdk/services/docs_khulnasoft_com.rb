# frozen_string_literal: true

module KDK
  module Services
    class DocsKhulnasoftCom < Base
      BASE_COMMAND = "support/exec-cd docs-gitlab-com hugo serve --cleanDestinationDir --baseURL %{protocol}://%{hostname} --port %{port} --bind %{hostname}"
      HTTPS_COMMAND = ' --tlsAuto'

      def name
        'docs-gitlab-com'
      end

      def command
        base_command = format(BASE_COMMAND, { protocol: protocol, hostname: config.hostname, port: config.docs_khulnasoft_com.port })

        return base_command unless config.https?

        base_command << HTTPS_COMMAND
      end

      def protocol
        config.https? ? :https : :http
      end

      def ready_message
        "KhulnaSoft Docs is available at #{protocol}://#{config.hostname}:#{config.docs_khulnasoft_com.port}."
      end

      def enabled?
        config.docs_khulnasoft_com.enabled?
      end
    end
  end
end
