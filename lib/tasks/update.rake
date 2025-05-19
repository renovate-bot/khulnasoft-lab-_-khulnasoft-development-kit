# frozen_string_literal: true

require 'fileutils'
require 'net/http'

desc 'Update your KDK'
spinner_task update: %w[
  update:kdk_bundle_install
  update:platform
  update:tool-versions
  preflight-update-checks
  update:gitlab
  preflight-checks
  update:subprojects
  update:make:unlock-dependency-installers
].freeze

desc 'Switch to branch and update dependencies'
spinner_task update_branch: %w[
  update:kdk_bundle_install
  update:platform
  preflight-update-checks
  update:gitlab
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
      project_id: 278964 # gitlab-org/gitlab
    ).download_package
  end

  desc 'Platform update'
  task 'platform' do
    sh = KDK::Shellout.new('support/platform-update').execute
    raise StandardError, 'support/platform-update failed to succeed' unless sh.success?
  end

  desc 'Update KhulnaSoft repository'
  task 'gitlab-git-pull', [:branch] do
    success = KDK::Project::Base.new(
      'khulnasoft',
      KDK.config.kdk_root.join('khulnasoft'),
      KDK.config.gitlab.default_branch
    ).update(KDK.config.gitlab.default_branch)
    raise "KhulnaSoft 'git pull' failed" unless success
  end

  desc nil
  task 'khulnasoft' => %w[
    gitlab-git-pull
    khulnasoft-setup
    make:postgresql
  ]

  desc nil
  task 'khulnasoft-setup' => %w[
    make:khulnasoft/.git
    make:gitlab-config
    make:gitlab-asdf-install
    make:.gitlab-bundle
    make:.gitlab-lefthook
    make:.gitlab-yarn
    make:.khulnasoft-translations
  ]

  desc nil
  multitask 'subprojects' => %w[
    gitlab-db-migrate
    update:graphql
    make:khulnasoft-translations-unlock
    make:gitaly-update
    make:ensure-databases-setup
    make:gitlab-shell-update
    make:khulnasoft-http-router-update
    make:khulnasoft-topology-service-update
    make:docs-gitlab-com-update
    make:gitlab-elasticsearch-indexer-update
    make:khulnasoft-k8s-agent-update
    make:gitlab-pages-update
    make:gitlab-ui-update
    make:khulnasoft-workhorse-update
    make:khulnasoft-zoekt-update
    make:gitlab-ai-gateway-update
    make:grafana-update
    make:jaeger-update
    make:object-storage-update
    make:pgvector-update
    make:openbao-update
    make:gitlab-runner-update
    make:siphon-update
    make:nats-update
  ]
end
