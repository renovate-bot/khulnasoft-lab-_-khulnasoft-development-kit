# frozen_string_literal: true

desc 'Reconfigure your KDK'
spinner_task reconfigure:  %w[
  Procfile
  reconfigure:make:postgresql
  reconfigure:subprojects
  reconfigure:make:kdk-reconfigure-task
].freeze

namespace :reconfigure do
  Support::Rake::Reconfigure.make_tasks.each do |make_task|
    desc "Run `make #{make_task.target}`"
    task "make:#{make_task.target}" do |t|
      t.skip! if make_task.skip?

      success = KDK.make(make_task.target).success?
      raise Support::Rake::TaskWithLogger::MakeError, make_task.target unless success
    end
  end

  subprojects = %w[
    jaeger-setup
    openssh-setup
    nginx-setup
    registry-setup
    elasticsearch-setup
    khulnasoft-runner-setup
    runner-setup
    geo-config
    khulnasoft-topology-service-setup
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
    siphon-setup
    nats-setup
  ].map { |task| "make:#{task}" }

  desc nil
  multitask subprojects: subprojects
end
