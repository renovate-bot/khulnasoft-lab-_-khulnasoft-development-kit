# frozen_string_literal: true

module KDK
  module Services
    # Rails web frontend server
    class Vite < Base
      def name
        'vite'
      end

      def command
        %(support/exec-cd khulnasoft bundle exec vite dev)
      end

      def enabled?
        config.vite.enabled?
      end

      def https?
        config.https? || config.vite.https?
      end

      def validate!
        return unless config.vite? && config.webpack?

        raise KDK::ConfigSettings::UnsupportedConfiguration, <<~MSG.strip
          Running vite and webpack at the same time is unsupported.
          Consider running `kdk config set webpack.enabled false` to disable webpack
        MSG
      end

      def env
        e = {
          KHULNASOFT_UI_WATCH: config.khulnasoft_ui?,
          VITE_RUBY_PORT: config.vite.port
        }

        e[:VUE_VERSION] = config.vite.vue_version if config.vite.vue_version == 3

        e
      end
    end
  end
end
