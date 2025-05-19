# frozen_string_literal: true

module KDK
  module Diagnostic
    class Firewall < Base
      TITLE = 'macOS firewall'

      def success?
        return true unless KDK::Telemetry.team_member?
        return true unless KDK::Machine.macos?

        firewall_disabled?
      end

      def detail
        return if success?

        <<~MESSAGE
          If you are using a managed firewall like SentinelOne or CrowdStrike, we
          recommend disabling the macOS firewall through Settings > Network > Firewall
          to prevent performance problems.
        MESSAGE
      end

      private

      def firewall_disabled?
        @firewall_state ||= KDK::Shellout.new(%w[/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate]).run

        @firewall_state.include?('State = 0')
      end
    end
  end
end
