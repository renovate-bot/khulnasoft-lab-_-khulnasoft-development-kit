# frozen_string_literal: true

require 'time'

module KDK
  module Command
    # Handles `kdk update` command execution
    class Update < BaseCommand
      GdkNotFoundError = Class.new(StandardError)
      WEEK_IN_SECONDS = 7 * 24 * 60 * 60

      def run(_args = [])
        success = update!

        success = run_rake(:reconfigure) if success && config.kdk.auto_reconfigure?

        if success
          Announcements.new.render_all
          KDK::Output.success('Successfully updated!')
          run_weekly_diagnostics
        else
          KDK::Output.error('Failed to update.', report_error: false)
          display_help_message
        end

        success
      rescue Support::Rake::TaskWithLogger::LoggerError => e
        e.print!
        false
      ensure
        check_kdk_available
      end

      private

      def update!
        KDK::Hooks.with_hooks(config.kdk.update_hooks, 'kdk update') do
          # Run `self-update` first to make sure Makefiles are up-to-date.
          # This ensures the next `make update` call works with the latest updates and instructions.
          if self_update?
            result = self_update!
            next false unless result
          end

          old_env = ENV.to_h
          ENV.merge! update_env

          success = run_rake('kdk:migrate')
          success = run_rake(:update) if success

          success
        ensure
          update_env.keys.map { |k| ENV.delete(k) }
          ENV.merge! old_env || {}
        end
      end

      def self_update!
        previous_revision = current_git_revision
        sh = KDK.make('self-update')

        return false unless sh.success?

        if previous_revision != current_git_revision
          Dir.chdir(config.kdk_root.to_s)
          ENV['KDK_SELF_UPDATE'] = '0'
          Kernel.exec 'kdk update'
        end

        true
      end

      def self_update?
        %w[1 yes true].include?(ENV.fetch('KDK_SELF_UPDATE', '1'))
      end

      def update_env
        {
          'PG_AUTO_UPDATE' => '1',
          'KDK_SKIP_MAKEFILE_TIMEIT' => '1'
        }
      end

      def current_git_revision
        Shellout.new(%w[git rev-parse HEAD], chdir: config.kdk_root).run
      end

      def check_kdk_available
        return if Utils.executable_exist_via_tooling_manager?('kdk')

        out.error('The `kdk` is no longer available after `kdk update`. This is unexpected, please report this in https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/2388.')

        KDK::Telemetry.capture_exception(GdkNotFoundError.new('`kdk` command is no longer available'))
      end

      def run_weekly_diagnostics
        return unless KDK::ReminderHelper.should_run_reminder?('diagnostics')

        # Empty for now. Add diagnostic checks here as needed.
        diagnostics = []

        diagnostics.each do |diagnostic|
          next if diagnostic.success?

          KDK::Output.puts
          KDK::Output.warn('Upcoming change notice - Action required:')
          KDK::Output.divider
          KDK::Output.puts(diagnostic.detail.strip)
          KDK::Output.divider
          KDK::Output.info('We will send you a reminder in a week to help you prepare for this change.')
        end

        KDK::ReminderHelper.update_reminder_timestamp!('diagnostics')
      end
    end
  end
end
