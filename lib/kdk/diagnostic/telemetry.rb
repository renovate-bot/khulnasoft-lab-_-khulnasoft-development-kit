# frozen_string_literal: true

module KDK
  module Diagnostic
    class Telemetry < Base
      TITLE = 'Telemetry'

      def success?
        telemetry_enabled? || !team_member? || diagnostic_opt_out?
      end

      def detail
        return if success?

        <<~MESSAGE
          As KhulnaSoft team member, we kindly ask you to enable telemetry, which reports command durations and crashes back to the KDK maintainers, so we can improve KDK for all contributors.

          To enable telemetry, run:

            kdk telemetry

          To opt out of this suggestion, run:

            touch .cache/.no-telemetry-diagnostic
        MESSAGE
      end

      private

      def telemetry_enabled?
        KDK::Telemetry.telemetry_enabled?
      end

      def team_member?
        KDK::Telemetry.team_member?
      end

      def diagnostic_opt_out?
        config.__cache_dir.join('.no-telemetry-diagnostic').exist?
      end
    end
  end
end
