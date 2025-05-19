# frozen_string_literal: true

require 'fileutils'
require 'net/http'

desc 'Update your KDK'
spinner_task update: %w[
  update:kdk_bundle_install
  update:platform
  update:tool-versions
  preflight-update-checks
  update:khulnasoft
  preflight-checks
  update:subprojects
  update:make:unlock-dependency-installers
].freeze

desc 'Switch to branch and update dependencies'
spinner_task update_branch: %w[
  update:kdk_bundle_install
  update:platform
  preflight-update-checks
  update:khulnasoft
  preflight-checks
  update:subprojects
  update:make:unlock-dependency-installers
]

namespace :update do
  Support::Rake::Update.make_tasks.each do |make_task|
    desc "Run `make #{make_task.target}`"
    task "make:#{make_task.target}" do |t|
      t.skip! if make_task.skip?

      success = KDK.make(make_task.target).success?
      raise Support::Rake::TaskWithLogger::MakeError, make_task.target unless success
    end
  end

  desc 'Install gems for KDK'
  task :kdk_bundle_install do
    sh = KDK::Shellout.new(%w[bundle install]).execute
    raise StandardError, 'bundle install failed to succeed' unless sh.success?
  end

  desc 'Download GraphQL schema'
  task 'graphql' do
    KDK::PackageHelper.new(
      package: :graphql_schema,
      project_id: 278964 # khulnasoft-org/khulnasoft
    ).download_package
  end

  desc 'Platform update'
  task 'platform' do
    sh = KDK::Shellout.new('support/platform-update').execute
    raise StandardError, 'support/platform-update failed to succeed' unless sh.success?
  end

  desc 'Update KhulnaSoft repository'
  task 'khulnasoft-git-pull', [:branch] do
    success = KDK::Project::Base.new(
      'khulnasoft',
      KDK.config.kdk_root.join('khulnasoft'),
      KDK.config.khulnasoft.default_branch
    ).update(KDK.config.khulnasoft.default_branch)
    raise "KhulnaSoft 'git pull' failed" unless success
  end

  desc nil
  task 'khulnasoft' => %w[
    khulnasoft-git-pull
    khulnasoft-setup
    make:postgresql
  ]

  desc nil
  task 'khulnasoft-setup' => %w[
    make:khulnasoft/.git
    make:khulnasoft-config
    make:khulnasoft-asdf-install
    make:.khulnasoft-bundle
    make:.khulnasoft-lefthook
    make:.khulnasoft-yarn
    make:.khulnasoft-translations
  ]

  desc nil
  multitask 'subprojects' => %w[
    khulnasoft-db-migrate
    update:graphql
    make:khulnasoft-translations-unlock
    make:gitaly-update
    make:ensure-databases-setup
    make:khulnasoft-shell-update
    make:khulnasoft-http-router-update
    make:khulnasoft-topology-service-update
    make:docs-khulnasoft-com-update
    make:khulnasoft-elasticsearch-indexer-update
    make:khulnasoft-k8s-agent-update
    make:khulnasoft-pages-update
    make:khulnasoft-ui-update
    make:khulnasoft-workhorse-update
    make:khulnasoft-zoekt-update
    make:khulnasoft-ai-gateway-update
    make:grafana-update
    make:jaeger-update
    make:object-storage-update
    make:pgvector-update
    make:openbao-update
    make:khulnasoft-runner-update
    make:siphon-update
    make:nats-update
  ]
end
