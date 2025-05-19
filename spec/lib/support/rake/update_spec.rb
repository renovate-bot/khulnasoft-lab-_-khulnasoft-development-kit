# frozen_string_literal: true

RSpec.describe Support::Rake::Update do
  before do
    stub_kdk_yaml({})
  end

  describe '.make_tasks' do
    it 'returns all make targets' do
      expect(described_class.make_tasks.map(&:target)).to match_array(%w[
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
        khulnasoft-http-router-update
        khulnasoft-topology-service-update
        docs-khulnasoft-com-update
        khulnasoft-elasticsearch-indexer-update
        khulnasoft-k8s-agent-update
        khulnasoft-pages-update
        khulnasoft-translations-unlock
        khulnasoft-ui-update
        khulnasoft-workhorse-update
        khulnasoft-zoekt-update
        khulnasoft-ai-gateway-update
        grafana-update
        jaeger-update
        object-storage-update
        pgvector-update
        zoekt-update
        openbao-update
        siphon-update
        nats-update
        khulnasoft-runner-update
      ])
    end

    it 'notes which tasks a skipped by default' do
      expect(described_class.make_tasks.filter(&:skip?).map(&:target)).to match_array(%w[
        docs-khulnasoft-com-update
        khulnasoft-elasticsearch-indexer-update
        khulnasoft-k8s-agent-update
        khulnasoft-pages-update
        khulnasoft-ui-update
        khulnasoft-zoekt-update
        khulnasoft-ai-gateway-update
        grafana-update
        jaeger-update
        object-storage-update
        pgvector-update
        zoekt-update
        openbao-update
        siphon-update
        nats-update
        khulnasoft-runner-update
      ])
    end

    context 'when a corresponding default-disabled service is enabled' do
      before do
        stub_kdk_yaml({
          'openbao' => { 'enabled' => 'true' }
        })
      end

      it 'no longer notes that task as skipped' do
        expect(described_class.make_tasks.filter(&:skip?).map(&:target)).not_to include('openbao-update')
      end
    end
  end
end
