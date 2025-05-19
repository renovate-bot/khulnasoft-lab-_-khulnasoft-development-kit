# frozen_string_literal: true

module KDK
  module Services
    # NATS is a simple, secure and high performance open source data layer for microservices architectures.
    # It is an integral part of our data insights pipeline.
    class Nats < Base
      def name
        'nats'
      end

      def command
        %(./nats/nats-server -js -config support/nats/nats-server.conf)
      end

      def enabled?
        config.nats.enabled?
      end
    end
  end
end
