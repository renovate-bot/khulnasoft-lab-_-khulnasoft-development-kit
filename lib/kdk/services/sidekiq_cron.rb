# frozen_string_literal: true

module KDK
  module Services
    # A second sidekiq Service to enable cron polling with COVERBAND_ENABLED=false
    class SidekiqCron < RailsBackgroundJobs
      def name
        'sidekiq-cron'
      end

      def enabled?
        config.khulnasoft.sidekiq_cron.enabled?
      end

      def env
        {
          COVERBAND_ENABLED: false,
          KHULNASOFT_CRON_JOBS_POLL_INTERVAL: 1,
          SIDEKIQ_VERBOSE: config.khulnasoft.sidekiq_cron.verbose?,
          SIDEKIQ_QUEUES: config.khulnasoft.sidekiq_cron.sidekiq_queues.join(','),
          CACHE_CLASSES: config.khulnasoft.cache_classes,
          BUNDLE_GEMFILE: config.khulnasoft.rails.bundle_gemfile,
          SIDEKIQ_WORKERS: 1,
          ENABLE_BOOTSNAP: config.khulnasoft.rails.bootsnap?,
          RAILS_RELATIVE_URL_ROOT: config.relative_url_root,
          GITALY_DISABLE_REQUEST_LIMITS: config.khulnasoft.gitaly_disable_request_limits
        }
      end
    end
  end
end
