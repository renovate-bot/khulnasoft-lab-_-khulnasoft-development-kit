# frozen_string_literal: true

module KDK
  module Services
    class KhulnasoftUi < Base
      def name
        'khulnasoft-ui'
      end

      def enabled?
        config.khulnasoft_ui?
      end

      def command
        %(support/exec-cd khulnasoft-ui yarn build --watch)
      end

      def env
        {
          NODE_ENV: 'development'
        }
      end
    end
  end
end
