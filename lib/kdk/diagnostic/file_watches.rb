# frozen_string_literal: true

module KDK
  module Diagnostic
    class FileWatches < Base
      TITLE = 'Linux inotify limits'
      MAX_WATCHES_LOW = 100_000
      MAX_WATCHES_RECOMMENDED = 524_288
      PROC_FILE = '/proc/sys/fs/inotify/max_user_watches'

      def success?
        return true unless ::KDK::Machine.linux?

        max_user_watches >= MAX_WATCHES_LOW
      end

      def detail
        return if success?

        max_user_watches_message
      end

      private

      def max_user_watches_message
        <<~MAX_USER_WATCHES
          Your system's fs.inotify.max_user_watches value is low. This could
          cause failures in services that need to watch files, like webpack,
          Vite, Jest, and even your IDE.

          We recommend increasing the value to #{MAX_WATCHES_RECOMMENDED} by
          adding the following to your /etc/sysctl.conf file:

              fs.inotify.max_user_watches = #{MAX_WATCHES_RECOMMENDED}

          Then run this command to apply the change immediately:

              $ sudo sysctl -p
        MAX_USER_WATCHES
      end

      def max_user_watches
        File.read(PROC_FILE).to_i
      rescue StandardError
        MAX_WATCHES_RECOMMENDED
      end
    end
  end
end
