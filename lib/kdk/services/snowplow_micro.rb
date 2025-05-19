# frozen_string_literal: true

module KDK
  module Services
    class SnowplowMicro < Base
      def name
        'snowplow-micro'
      end

      def enabled?
        config.snowplow_micro?
      end

      def command
        dir = config.kdk_root.join('snowplow')
        port = config.snowplow_micro.port
        image = config.snowplow_micro.image

        %(docker run --rm --mount type=bind,source=#{dir},destination=/config -p #{port}:9091 #{image} --collector-config /config/snowplow_micro.conf --iglu /config/iglu.json)
      end
    end
  end
end
