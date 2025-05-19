# frozen_string_literal: true

module KDK
  module Services
    class Webpack < Base
      def name
        'webpack'
      end

      def command
        %(support/exec-cd khulnasoft yarn dev-server)
      end

      def enabled?
        config.webpack?
      end

      def env
        {
          NODE_ENV: 'development',
          DEV_SERVER_STATIC: config.webpack.static?,
          VUE_VERSION: config.webpack.__set_vue_version ? config.webpack.vue_version : nil,
          WEBPACK_VENDOR_DLL: config.webpack.vendor_dll?,
          DEV_SERVER_INCREMENTAL: config.webpack.incremental?,
          DEV_SERVER_INCREMENTAL_TTL: config.webpack.incremental_ttl,
          DEV_SERVER_LIVERELOAD: config.webpack.live_reload?,
          NO_SOURCEMAPS: !config.webpack.sourcemaps?,
          DEV_SERVER_PORT: config.webpack.port,
          DEV_SERVER_PUBLIC_ADDR: config.webpack.__dev_server_public,
          DEV_SERVER_HOST: config.webpack.host,
          DEV_SERVER_ALLOWED_HOSTS: config.webpack.allowed_hosts.join(','),
          KHULNASOFT_UI_WATCH: config.khulnasoft_ui?
        }.compact
      end
    end
  end
end
