# frozen_string_literal: true

module KDK
  module Diagnostic
    class PortInUse < Base
      TITLE = 'Port required by KDK is already in use'

      def success?
        !port_in_use?
      end

      def detail
        return if success?

        <<~MSG
          Port #{port} is currently in use by another process.

          This can happen if KDK was previously running and the directory was deleted before stopping it.
          In that case, some processes may still be running in the background and blocking the port.

          To fix this:

            1. Run `lsof -i @#{listen_address}:#{port}` to see which processes are using the port
            2. Use `kill -9 <PID>` to stop them
            3. Run `lsof -i @#{listen_address}:#{port}` again to confirm the port is free

          Once the port is no longer in use, try starting KDK again.
        MSG
      end

      private

      def port_in_use?
        pids = run("lsof -ti @#{listen_address}:#{port}").lines.map(&:strip).reject(&:empty?)
        return false if pids.empty?

        pids.any? do |pid|
          cmd = run("ps -p #{pid} -o args=").strip
          !cmd.include?(KDK.root.to_s)
        end
      end

      def listen_address
        KDK.config.listen_address
      end

      def port
        KDK.config.port
      end

      def run(command)
        Shellout.new(command, chdir: KDK.root).run
      end
    end
  end
end
