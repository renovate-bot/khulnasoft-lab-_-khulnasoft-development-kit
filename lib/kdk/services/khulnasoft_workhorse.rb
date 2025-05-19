# frozen_string_literal: true

module KDK
  module Services
    # KhulnaSoft Workhorse service
    class KhulnasoftWorkhorse < Base
      def name
        'khulnasoft-workhorse'
      end

      def command
        command = %W[/usr/bin/env PATH="#{workhorse_dir}:$PATH"]
        command << 'GEO_SECONDARY_PROXY=0' unless config.geo?
        command += %W[khulnasoft-workhorse -#{auth_type_flag} "#{auth_address}"]
        command += %W[-documentRoot "#{document_root}"]
        command += %W[-developmentMode -secretPath "#{secret_path}"]
        command += %W[-config "#{config_file}"]
        command += %W[-listenAddr "#{listen_address}"]
        command += %w[-logFormat json]
        command += %W[-apiCiLongPollingDuration "#{ci_long_polling_duration}"]
        command += %W[-prometheusListenAddr "#{prometheus_listen_addr}"] if config.prometheus.enabled?
        command += auth_backend_option

        command.join(' ')
      end

      def enabled?
        config.workhorse.enabled?
      end

      private

      def workhorse_dir
        config.khulnasoft.dir.join('workhorse')
      end

      def auth_backend_option
        relative_url_root = config.relative_url_root

        return [] if relative_url_root.to_s.empty?

        %W[-authBackend "http://localhost:8080#{relative_url_root}"]
      end

      def auth_type_flag
        config.workhorse.__listen_settings.__type
      end

      def auth_address
        config.workhorse.__listen_settings.__address
      end

      def document_root
        config.khulnasoft.dir.join('public').to_s
      end

      def secret_path
        config.khulnasoft.dir.join('.khulnasoft_workhorse_secret').to_s
      end

      def config_file
        workhorse_dir.join('config.toml')
      end

      def listen_address
        config.workhorse.__command_line_listen_addr
      end

      def ci_long_polling_duration
        "#{config.workhorse.ci_long_polling_seconds}s"
      end

      def prometheus_listen_addr
        "#{config.hostname}:#{config.prometheus.workhorse_exporter_port}"
      end
    end
  end
end
