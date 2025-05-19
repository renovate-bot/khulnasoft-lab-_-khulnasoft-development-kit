# frozen_string_literal: true

require 'pathname'

module KDK
  module Services
    class KhulnasoftHttpRouter < Base
      BASE_COMMAND = 'support/exec-cd khulnasoft-http-router npm run dev -- -c wrangler.toml --ip %{ip} --port %{port} --var KHULNASOFT_PROXY_HOST:%{proxy_host} --var KHULNASOFT_RULES_CONFIG:%{rules_config}'
      TOPOLOGY_SERVICE_COMMAND = ' --var KHULNASOFT_TOPOLOGY_SERVICE_URL:http://localhost:%{port}'
      HTTPS_COMMAND = ' --local-protocol https --https-key-path %{key_path} --https-cert-path %{certificate_path}'
      LOG_PATH = 'tmp/log/khulnasoft-http-router.log'

      def name
        'khulnasoft-http-router'
      end

      def command
        base_command = format(BASE_COMMAND, {
          ip: config.hostname,
          port: config.khulnasoft_http_router.use_distinct_port? ? config.khulnasoft_http_router.port : config.port,
          proxy_host: config.nginx? ? config.nginx.__listen_address : config.workhorse.__listen_address,
          rules_config: config.khulnasoft_http_router.khulnasoft_rules_config
        })

        if config.khulnasoft_topology_service.enabled?
          base_command << format(TOPOLOGY_SERVICE_COMMAND,
            { port: config.khulnasoft_topology_service.rest_port })
        end

        return base_command unless config.https?

        base_command << format(HTTPS_COMMAND, { key_path: key_path, certificate_path: certificate_path })
      end

      def ready_message
        "The HTTP Router is available at #{listen_address}."
      end

      def enabled?
        config.khulnasoft_http_router.enabled?
      end

      def env
        {
          WRANGLER_LOG_PATH: config.kdk_root.join(LOG_PATH)
        }.merge(https_env)
      end

      private

      def https_env
        return {} unless config.https?

        root_ca_dir =
          if Utils.executable_exist?('mkcert')
            mkcert_ca_root_dir
          else
            KDK.root
          end

        {
          NODE_EXTRA_CA_CERTS: File.join(root_ca_dir, 'rootCA.pem')
        }
      end

      def mkcert_ca_root_dir
        KDK::Shellout.new(%w[mkcert -CAROOT]).run.chomp
      end

      def protocol
        config.https? ? :https : :http
      end

      def listen_address
        klass = config.https? ? URI::HTTPS : URI::HTTP

        klass.build(host: config.hostname, port: active_port)
      end

      def key_path
        config.kdk_root.join(config.nginx.ssl.key)
      end

      def certificate_path
        config.kdk_root.join(config.nginx.ssl.certificate)
      end

      def active_port
        if config.khulnasoft_http_router.use_distinct_port?
          config.khulnasoft_http_router.port
        else
          config.port
        end
      end
    end
  end
end
