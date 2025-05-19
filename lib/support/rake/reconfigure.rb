# frozen_string_literal: true

require 'fileutils'

module Support
  module Rake
    class Reconfigure
      CORE_TARGETS = %w[
        postgresql
        kdk-reconfigure-task
      ].freeze

      def self.make_tasks(config: KDK.config)
        core_tasks + optional_tasks(config)
      end

      def self.core_tasks
        CORE_TARGETS.map { |target| make_task(target) }
      end

      # rubocop:disable Metrics/AbcSize
      def self.optional_tasks(config)
        [
          make_task('jaeger-setup', enabled: config.tracer.jaeger?),
          make_task('openssh-setup', enabled: config.sshd?),
          make_task('nginx-setup', enabled: config.nginx?),
          make_task('registry-setup', enabled: config.registry?),
          make_task('elasticsearch-setup', enabled: config.elasticsearch?),
          make_task('khulnasoft-elasticsearch-indexer-setup', enabled: config.elasticsearch?),
          make_task('khulnasoft-runner-setup', enabled: config.runner?),
          make_task('runner-setup', enabled: config.runner?),
          make_task('geo-config', enabled: config.geo?),
          make_task('khulnasoft-topology-service-setup', enabled: config.khulnasoft_topology_service?),
          make_task('khulnasoft-http-router-setup', enabled: config.khulnasoft_http_router?),
          make_task('docs-khulnasoft-com-setup', enabled: config.docs_khulnasoft_com?),
          make_task('khulnasoft-observability-backend-setup', enabled: config.khulnasoft_observability_backend?),
          make_task('khulnasoft-k8s-agent-setup', enabled: config.khulnasoft_k8s_agent?),
          make_task('khulnasoft-pages-setup', enabled: config.khulnasoft_pages?),
          make_task('khulnasoft-ui-setup', enabled: config.khulnasoft_ui?),
          make_task('khulnasoft-zoekt-setup', enabled: config.zoekt?),
          make_task('grafana-setup', enabled: config.grafana?),
          make_task('object-storage-setup', enabled: config.object_store?),
          make_task('openldap-setup', enabled: config.openldap?),
          make_task('pgvector-setup', enabled: config.pgvector?),
          make_task('prom-setup', enabled: config.prometheus?),
          make_task('snowplow-micro-setup', enabled: config.snowplow_micro?),
          make_task('duo-workflow-executor-setup', enabled: config.duo_workflow?),
          make_task('postgresql-replica-setup', enabled: config.postgresql.replica?),
          make_task('postgresql-replica-2-setup', enabled: config.postgresql.replica_2?),
          make_task('openbao-setup', enabled: config.openbao?),
          make_task('siphon-setup', enabled: config.siphon?),
          make_task('nats-setup', enabled: config.nats?)
        ]
      end
      # rubocop:enable Metrics/AbcSize

      def self.make_task(target, enabled: true)
        MakeTask.new(target: target, enabled: enabled)
      end
    end
  end
end
