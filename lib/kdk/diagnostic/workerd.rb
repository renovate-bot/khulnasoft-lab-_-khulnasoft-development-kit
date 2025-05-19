# frozen_string_literal: true

module KDK
  module Diagnostic
    class Workerd < Base
      TITLE = 'Workerd process check'
      MAX_ALLOWED_WORKERD_PROCESSES = 2

      def success?
        !too_many_processes?
      end

      def detail
        return if success?

        <<~DETAIL
        There are #{lingering_pids.count} `workerd` processes running but there should only be #{MAX_ALLOWED_WORKERD_PROCESSES} running at max.

        If your KDK has trouble booting, run the following command to kill all `workerd` processes:

        kill -9 #{lingering_pids.join(' ')}
        DETAIL
      end

      private

      def too_many_processes?
        lingering_pids.count > MAX_ALLOWED_WORKERD_PROCESSES
      end

      def lingering_pids
        @lingering_pids ||= begin
          Shellout.new(%w[ps x]).run.split("\n").filter { |a| a.include?(config.kdk_root.join('khulnasoft-http-router').to_s) && a.include?('bin/workerd') }.map { |a| a.split[0].to_i }
        rescue Errno::ENOENT
          [] # in case `ps` is not available
        end
      end
    end
  end
end
