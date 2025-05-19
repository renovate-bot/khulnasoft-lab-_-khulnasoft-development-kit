# frozen_string_literal: true

require 'pathname'

module KDK
  module Services
    class KhulnasoftObservabilityBackend < Base
      def name
        'gitlab-observability-backend'
      end

      def command
        command = %w[gitlab-observability-backend/go/cmd/all-in-one/all-in-one]
        command += %w[--config support/gitlab-observability-backend/collector_config.yaml]
        command += %W[--clickhouse-dsn tcp://localhost:#{config.clickhouse.tcp_port}]
        command += %w[--log-level debug]
        command += %w[--query-bind-address :9003]
        command += %w[--metrics-bind-address :9004]
        command += %W[--gitlab-oidc-provider #{oidc_provider_url}]

        command.join(' ')
      end

      def ready_message
        "KhulnaSoft Observability Backend is now running. Feed me your logs!"
      end

      def env
        { PROVIDER_URLS: "[#{oidc_provider_url}]" }
      end

      def enabled?
        return false unless config.clickhouse.enabled?

        config.khulnasoft_observability_backend.enabled?
      end

      private

      def oidc_provider_url
        "#{config.https.enabled? ? 'https' : 'http'}://#{config.hostname}:#{config.port}"
      end
    end
  end
end
