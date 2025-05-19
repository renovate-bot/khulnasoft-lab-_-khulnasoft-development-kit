# frozen_string_literal: true

module KDK
  module Services
    # ClickHouse Service
    class Clickhouse < Base
      def name
        'clickhouse'
      end

      def command
        %(#{config.clickhouse.bin} server --config-file=#{clickhouse_config})
      end

      def enabled?
        config.clickhouse.enabled?
      end

      private

      def clickhouse_config
        config.clickhouse.dir.join('config.xml')
      end
    end
  end
end
