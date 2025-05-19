# frozen_string_literal: true

RSpec.describe Support::Rake::Reconfigure do
  before do
    stub_kdk_yaml({})
  end

  describe '.make_tasks' do
    it 'returns all make targets' do
      expect(described_class.make_tasks.map(&:target)).to match_array(%w[
        jaeger-setup
        khulnasoft-topology-service-setup
        postgresql
        openssh-setup
        nginx-setup
        registry-setup
        elasticsearch-setup
        khulnasoft-runner-setup
        runner-setup
        geo-config
        khulnasoft-http-router-setup
        docs-khulnasoft-com-setup
        khulnasoft-observability-backend-setup
        khulnasoft-elasticsearch-indexer-setup
        khulnasoft-k8s-agent-setup
        khulnasoft-pages-setup
        khulnasoft-ui-setup
        khulnasoft-zoekt-setup
        grafana-setup
        object-storage-setup
        openldap-setup
        pgvector-setup
        prom-setup
        snowplow-micro-setup
        duo-workflow-executor-setup
        postgresql-replica-setup
        postgresql-replica-2-setup
        openbao-setup
        kdk-reconfigure-task
        siphon-setup
        nats-setup
      ])
    end
  end
end
