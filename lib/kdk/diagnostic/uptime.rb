# frozen_string_literal: true

module KDK
  module Diagnostic
    class Uptime < Base
      TITLE = 'Uptime'
      MAX_UPTIME_HOURS = 24

      def success?
        @success ||= uptime_hours.nil? || uptime_hours < MAX_UPTIME_HOURS
      end

      def detail
        return if success?

        <<~MESSAGE
          Your machine has been up for #{uptime_hours.floor} hours.

          We highly recommended that you reboot your machine if you are encountering
          issues with KDK and it has been up for more than #{MAX_UPTIME_HOURS} hours.
        MESSAGE
      end

      private

      def uptime_hours
        uptime = KDK::Machine.uptime

        return nil if uptime.nil?

        uptime.to_f / 60 / 60
      end
    end
  end
end
