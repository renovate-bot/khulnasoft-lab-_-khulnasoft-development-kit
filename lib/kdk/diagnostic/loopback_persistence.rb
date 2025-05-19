# frozen_string_literal: true

module KDK
  module Diagnostic
    class LoopbackPersistence < Loopback
      TITLE = 'Loopback interface persistence'
      LAUNCHDAEMON_PLIST = '/Library/LaunchDaemons/org.khulnasoft1.ifconfig.plist'

      def success?
        return true unless needs_loopback?
        return true unless KDK::Machine.macos?

        loopback_daemon_file_ownership_correct?
      end

      def detail
        return if success?

        <<~MESSAGE
          You have configured a Launch Daemon in #{LAUNCHDAEMON_PLIST}, but
          the ownership/permissions are incorrect.

          You can fix this by running the following command:

            sudo chown root:wheel #{LAUNCHDAEMON_PLIST};
            sudo chmod 0644 #{LAUNCHDAEMON_PLIST};
        MESSAGE
      end

      def loopback_daemon_file_ownership_correct?
        root_uid = Process::UID.from_name('root')
        wheel_gid = Process::GID.from_name('wheel')
        stat = File.lstat(LAUNCHDAEMON_PLIST)
        stat.uid == root_uid && stat.gid == wheel_gid && stat.mode & 0o777 == 0o644
      rescue Errno::ENOENT, ArgumentError
        true
      end
    end
  end
end
