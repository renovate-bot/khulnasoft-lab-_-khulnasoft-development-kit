# frozen_string_literal: true

module KDK
  module Services
    # A second sidekiq Service to enable cron polling with COVERBAND_ENABLED=false
    class SidekiqCron < RailsBackgroundJobs
      def name
        'sidekiq-cron'
      end

      def enabled?
        config.gitlab.sidekiq_cron.enabled?
      end

      def env
        {
          COVERBAND_ENABLED: false,
          KHULNASOFT_CRON_JOBS_POLL_INTERVAL: 1,
          SIDEKIQ_VERBOSE: config.gitlab.sidekiq_cron.verbose?,
          SIDEKIQ_QUEUES: config.gitlab.sidekiq_cron.sidekiq_queues.join(','),
          CACHE_CLASSES: config.gitlab.cache_classes,
          BUNDLE_GEMFILE: config.gitlab.rails.bundle_gemfile,
          SIDEKIQ_WORKERS: 1,
          ENABLE_BOOTSNAP: config.gitlab.rails.bootsnap?,
          RAILS_RELATIVE_URL_ROOT: config.relative_url_root,
          GITALY_DISABLE_REQUEST_LIMITS: config.gitlab.gitaly_disable_request_limits
        }
      end
    end
  end
end
