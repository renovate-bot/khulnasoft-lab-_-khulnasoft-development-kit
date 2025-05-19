# frozen_string_literal: true

module KDK
  module Command
    class Kill < BaseCommand
      def run(arguments = [])
        if runsv_processes_to_kill.empty?
          KDK::Output.info('No runsv processes detected.')
          return true
        end

        return true unless continue?(arguments)

        if kill_runsv_processes!
          KDK::Output.success("All 'runsv' processes have been terminated.")
          true
        else
          message = "Failed to kill all 'runsv' processes."
          message = "#{message} The following are still running:\n\n" unless runsv_processes_to_kill.empty?

          KDK::Output.error(message)
          KDK::Output.puts("#{runsv_processes_to_kill}\n\n") unless runsv_processes_to_kill.empty?
          false
        end
      end

      private

      def runsv_processes_to_kill
        Shellout.new('ps -ef | grep "[r]unsv"').try_run
      end

      def continue?(arguments)
        return true if arguments.include?('-y')

        KDK::Output.warn("You're about to kill the following runsv processes:\n\n")
        KDK::Output.puts("#{runsv_processes_to_kill}\n\n")

        return true if ENV.fetch('KDK_KILL_CONFIRM', 'false') == 'true' || !KDK::Output.interactive?

        KDK::Output.info("This command will stop all your KDK instances and any other process started by runit.\n\n")

        KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      end

      def kill_runsv_processes!
        kdk_stop_succeeded? || pkill_runsv_succeeded? || pkill_force_runsv_succeeded?
      end

      def kdk_stop_succeeded?
        KDK::Output.info("Running 'kdk stop' to be sure..")
        Runit.stop && wait && runsv_processes_to_kill.empty?
      end

      def pkill_runsv_succeeded?
        pkill('runsv') && wait && runsv_processes_to_kill.empty?
      end

      def pkill_force_runsv_succeeded?
        pkill('-9 runsv') && wait && runsv_processes_to_kill.empty?
      end

      def pkill(args)
        command = "pkill #{args}"
        KDK::Output.info("Running '#{command}'..")
        sh = Shellout.new(command)
        sh.try_run

        # pkill returns 0 if one ore more processes were matched or 1 if no
        # processes were matched.
        [0, 1].include?(sh.exit_code)
      end

      def wait(length: 5)
        KDK::Output.info("Giving runsv processes #{length} seconds to terminate..")
        sleep(length)
      end
    end
  end
end
