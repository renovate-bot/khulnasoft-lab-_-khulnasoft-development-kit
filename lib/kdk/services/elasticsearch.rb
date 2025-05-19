# frozen_string_literal: true

module KDK
  module Services
    class Elasticsearch < Base
      def name
        'elasticsearch'
      end

      def enabled?
        config.elasticsearch.enabled?
      end

      def command
        %(elasticsearch/bin/elasticsearch)
      end
    end
  end
end
