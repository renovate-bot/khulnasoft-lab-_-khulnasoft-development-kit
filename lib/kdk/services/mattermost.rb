# frozen_string_literal: true

module KDK
  module Services
    class Mattermost < Base
      def name
        'mattermost'
      end

      def command
        %W[docker run --rm --init
          -v #{config.kdk_root.join('mattermost', 'data')}:/mm/mattermost-data/
          -v #{config.kdk_root.join('mattermost', 'mysql')}:/var/lib/mysql
          --publish #{config.mattermost.port}:8065
          #{config.mattermost.image}].join(' ')
      end

      def enabled?
        config.mattermost?
      end
    end
  end
end
