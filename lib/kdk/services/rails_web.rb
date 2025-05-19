# frozen_string_literal: true

module KDK
  module Services
    # Rails web frontend server
    class RailsWeb < Base
      def name
        'rails-web'
      end

      def command
        %(support/exec-cd gitlab bin/web start_foreground)
      end

      def enabled?
        config.rails_web?
      end

      def env
        e = {
          CACHE_CLASSES: config.gitlab.cache_classes,
          BUNDLE_GEMFILE: config.gitlab.rails.bundle_gemfile,
          ENABLE_BOOTSNAP: config.gitlab.rails.bootsnap?,
          RAILS_RELATIVE_URL_ROOT: config.relative_url_root,
          ACTION_CABLE_IN_APP: 'true',
          ACTION_CABLE_WORKER_POOL_SIZE: config.action_cable.worker_pool_size,
          GITALY_DISABLE_REQUEST_LIMITS: config.gitlab.gitaly_disable_request_limits
        }

        e[:KDK_GEO_SECONDARY] = 1 if config.geo? && config.geo.secondary?

        e
      end

      def ready_message
        debug_info = KDK::Command::DebugInfo.new

        <<~MESSAGE
          KhulnaSoft available at #{config.__uri}.
            - Ruby: #{debug_info.ruby_version}.
            - Node.js: #{debug_info.node_version}.
        MESSAGE
      end
    end
  end
end
