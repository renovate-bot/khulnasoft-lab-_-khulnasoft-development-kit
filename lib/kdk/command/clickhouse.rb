# frozen_string_literal: true

module KDK
  module Command
    # Executes clickhouse client command with configured connection paras and any provided extra arguments
    class Clickhouse < BaseCommand
      def run(args = [])
        unless KDK.config.clickhouse.enabled?
          KDK::Output.error('ClickHouse is not enabled. Please check your kdk.yml configuration.', report_error: false)

          exit(-1)
        end

        exec(*command(args), chdir: KDK.root)
      end

      private

      def command(args = [])
        clickhouse = config.clickhouse

        base = %W[#{clickhouse.bin} client --port=#{clickhouse.tcp_port}]
        (base + args).flatten
      end
    end
  end
end
