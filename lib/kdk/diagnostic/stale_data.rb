# frozen_string_literal: true

module KDK
  module Diagnostic
    class StaleData < Base
      TITLE = 'Stale Data'

      def success?
        !stale_data_needing_attention?
      end

      def detail
        stale_data_message unless success?
      end

      private

      def stale_data_message
        <<~MESSAGE
          You might encounter a PG::CheckViolation error during database migrations, likely due to stale data in the ci database that belongs in the main database, or vice versa. To address this, you can run:

            kdk truncate-legacy-tables
        MESSAGE
      end

      def stale_data_needing_attention?
        KDK::Command::TruncateLegacyTables.new.truncation_needed?
      end
    end
  end
end
