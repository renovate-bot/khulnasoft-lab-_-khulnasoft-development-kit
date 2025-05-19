# frozen_string_literal: true

require 'fileutils'

module Support
  module Rake
    class Update
      CORE_TARGETS = %w[
        khulnasoft/.git
        khulnasoft-config
        khulnasoft-asdf-install
        .khulnasoft-bundle
        .khulnasoft-lefthook
        .khulnasoft-yarn
        .khulnasoft-translations
        postgresql
        khulnasoft/doc/api/graphql/reference/khulnasoft_schema.json
        preflight-checks
        preflight-update-checks
        gitaly-update
        ensure-databases-setup
        khulnasoft-shell-update
        unlock-dependency-installers
        khulnasoft-translations-unlock
        khulnasoft-workhorse-update
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
          make_task('khulnasoft-http-router-update', enabled: config.khulnasoft_http_router.enabled?),
          make_task('khulnasoft-topology-service-update', enabled: config.khulnasoft_topology_service.enabled?),
          make_task('docs-khulnasoft-com-update', enabled: config.docs_khulnasoft_com.enabled?),
          make_task('khulnasoft-elasticsearch-indexer-update', enabled: config.elasticsearch.enabled?),
          make_task('khulnasoft-k8s-agent-update', enabled: config.khulnasoft_k8s_agent.enabled?),
          make_task('khulnasoft-pages-update', enabled: config.khulnasoft_pages.enabled?),
          make_task('khulnasoft-ui-update', enabled: config.khulnasoft_ui.enabled?),
          make_task('khulnasoft-zoekt-update', enabled: config.zoekt.enabled?),
          make_task('khulnasoft-ai-gateway-update', enabled: config.khulnasoft_ai_gateway.enabled?),
          make_task('grafana-update', enabled: config.grafana.enabled?),
          make_task('jaeger-update', enabled: config.tracer.jaeger.enabled?),
          make_task('object-storage-update', enabled: config.object_store.enabled?),
          make_task('pgvector-update', enabled: config.pgvector.enabled?),
          make_task('zoekt-update', enabled: config.zoekt.enabled?),
          make_task('openbao-update', enabled: config.openbao.enabled?),
          make_task('khulnasoft-runner-update', enabled: config.khulnasoft_runner.enabled?),
          make_task('siphon-update', enabled: config.siphon.enabled?),
          make_task('nats-update', enabled: config.nats.enabled?)
        ]
      end
      # rubocop:enable Metrics/AbcSize

      def self.make_task(target, enabled: true)
        MakeTask.new(target: target, enabled: enabled)
      end
    end
  end
end
