# frozen_string_literal: true

module KDK
  module Diagnostic
    class Pguser < Base
      TITLE = 'PGUSER environment variable'

      def success?
        !pguser_set?
      end

      def detail
        pguser_set_message unless success?
      end

      private

      def pguser_set?
        ENV.has_key? 'PGUSER'
      end

      def pguser_set_message
        <<~MESSAGE
          The PGUSER environment variable is set and may cause issues with
          underlying postgresql commands ran by KDK.
        MESSAGE
      end
    end
  end
end
