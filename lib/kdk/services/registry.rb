# frozen_string_literal: true

module KDK
  module Services
    class Registry < Base
      DIRECTORY = 'container-registry'

      def name
        'registry'
      end

      def enabled?
        config.registry.enabled?
      end

      def command
        %(support/exec-cd #{DIRECTORY} bin/registry serve #{config_path})
      end

      private

      def config_path
        config.kdk_root.join('registry', 'config.yml')
      end
    end
  end
end
