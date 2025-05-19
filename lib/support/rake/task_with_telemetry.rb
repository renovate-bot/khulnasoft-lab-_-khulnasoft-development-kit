# frozen_string_literal: true

module Support
  module Rake
    module TaskWithTelemetry
      def execute(...)
        @telemetry_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          super
          send_telemetry!(success: true)
        rescue StandardError
          send_telemetry!(success: false)
          raise
        end
      end

      private

      def telemetry_name
        "rake #{name}"
      end

      def send_telemetry!(success:)
        return unless KDK::Telemetry.telemetry_enabled?

        duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @telemetry_start
        KDK::Telemetry.send_telemetry(success, telemetry_name, duration: duration)
      end
    end
  end
end
