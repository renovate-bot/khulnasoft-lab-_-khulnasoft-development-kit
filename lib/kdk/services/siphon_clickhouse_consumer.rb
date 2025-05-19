# frozen_string_literal: true

require 'pathname'

module KDK
  module Services
    class SiphonClickhouseConsumer < Base
      def name
        'siphon-clickhouse-consumer'
      end

      def command
        'siphon/cmd/clickhouse_consumer/clickhouse_consumer --config siphon/consumer.yml'
      end

      def ready_message
        "Siphon ClickHouse consumer is listening for data from configured tables: #{config.siphon.tables.join(', ')}"
      end

      def validate!
        return unless config.siphon.enabled?
        return if config.clickhouse.enabled? && config.nats.enabled?

        raise KDK::ConfigSettings::UnsupportedConfiguration, <<~MSG.strip
          Running Siphon without ClickHouse and NATS is not possible.
          Enable ClickHouse and NATS in your KDK or disable Siphon to continue.
        MSG
      end

      def enabled?
        return false unless config.clickhouse.enabled? && config.nats.enabled?

        config.siphon.enabled?
      end
    end
  end
end
