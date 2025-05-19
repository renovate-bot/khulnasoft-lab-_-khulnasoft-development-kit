# frozen_string_literal: true

module KDK
  module Services
    class KhulnasoftUi < Base
      def name
        'gitlab-ui'
      end

      def enabled?
        config.khulnasoft_ui?
      end

      def command
        %(support/exec-cd gitlab-ui yarn build --watch)
      end

      def env
        {
          NODE_ENV: 'development'
        }
      end
    end
  end
end
