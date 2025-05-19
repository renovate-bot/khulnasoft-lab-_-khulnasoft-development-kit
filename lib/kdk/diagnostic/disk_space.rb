# frozen_string_literal: true

module KDK
  module Diagnostic
    class DiskSpace < Base
      TITLE = 'Disk space'
      GB = 1000 * 1000 * 1000
      # Half of what we recommend in README.md.
      MIN_AVAILABLE_DISK_SPACE = 15 * GB

      def success?
        enough_disk_space?
      end

      def detail
        return if success?

        <<~MESSAGE
          You only have #{(available_disk_space / GB).round(1)} GB available on the disk where KDK is installed.

          We recommend that you keep #{(MIN_AVAILABLE_DISK_SPACE / GB).round(1)} GB available for KDK to work optimally.
        MESSAGE
      end

      private

      def enough_disk_space?
        available_disk_space >= MIN_AVAILABLE_DISK_SPACE
      end

      def available_disk_space
        @available_disk_space ||= KDK::Machine.available_disk_space
      end
    end
  end
end
