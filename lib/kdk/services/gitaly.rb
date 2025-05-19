# frozen_string_literal: true

module KDK
  module Services
    class Gitaly < Base
      def name
        'gitaly'
      end

      def command
        %(support/exec-cd gitaly #{config.gitaly.__gitaly_build_bin_path} serve #{config.gitaly.config_file})
      end

      def enabled?
        config.gitaly?
      end

      def env
        {
          GITALY_TESTING_ENABLE_ALL_FEATURE_FLAGS: config.gitaly.enable_all_feature_flags?
        }.merge(config.gitaly.env)
      end
    end
  end
end
