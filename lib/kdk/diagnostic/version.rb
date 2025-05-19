# frozen_string_literal: true

require 'date'

module KDK
  module Diagnostic
    class Version < Base
      TITLE = 'KDK Version'
      MAX_ALLOWED_DAYS = 7

      def success?
        !outdated?
      end

      def detail
        return if success?

        <<~MESSAGE
          An update for KDK is available.
            - The latest commit of your KDK is #{days_old} days old.
            - #{version.diff_message}
        MESSAGE
      end

      private

      # If current commit is less than MAX_ALLOWED_DAYS old, we don't even fetch the most recent
      # commit to compare. Otherwise, compares if the current commit is more the MAX_ALLOWED_DAYS
      # older than latest_main_commit
      def outdated?
        return false if days_old < MAX_ALLOWED_DAYS

        days_between(
          version.latest_main_commit.timestamp,
          version.current_commit.timestamp
        ) >= MAX_ALLOWED_DAYS
      end

      def days_old
        @days_old ||= days_between(::Date.today, version.current_commit.timestamp)
      end

      def days_between(start_date, end_date)
        (start_date - end_date).to_i
      end

      def version
        @version ||= ::KDK::VersionChecker.new(
          service_path: KDK.root
        )
      end
    end
  end
end
