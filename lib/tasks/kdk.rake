# frozen_string_literal: true

namespace :kdk do
  migrations = %w[
    migrate:update_telemetry_settings
    migrate:mise
  ]

  desc 'Run migration related to KDK setup'
  task migrate: migrations

  namespace :migrate do
    desc 'Update settings to turn on telemetry for KhulnaSoft team members (determined by @khulnasoft.com email in git config) and anonymize usernames for all users'
    task :update_telemetry_settings do
      telemetry_enabled = KDK.config.telemetry.enabled
      is_team_member = KDK::Telemetry.team_member?
      should_update = telemetry_enabled || is_team_member

      if should_update
        KDK::Output.info('Telemetry has been automatically enabled for you as a KhulnaSoft team member.') if !telemetry_enabled && is_team_member

        KDK::Telemetry.update_settings('y')
      end
    end

    desc 'Prompts KhulnaSoft team members to migrate from asdf to mise if asdf is still in use'
    task :mise do
      next unless !KDK.config.asdf.opt_out? && !KDK.config.mise.enabled && KDK::Telemetry.team_member?
      next unless KDK::ReminderHelper.should_run_reminder?('mise_migration')

      diagnostic = KDK::Diagnostic::ToolVersionManager.new
      KDK::Output.warn(diagnostic.detail(:update))
      KDK::Output.puts

      unless KDK::Output.interactive?
        KDK::Output.info('Skipping mise migration prompt in non-interactive environment.')
        next
      end

      if KDK::Output.prompt('Would you like it to switch to mise now? [y/N]').match?(/\Ay(?:es)*\z/i)
        KDK::Output.info('Great! Running the mise migration now..')
        diagnostic.correct!
      else
        KDK::Output.info("No worries. We'll remind you again in 5 days.")
        KDK::ReminderHelper.update_reminder_timestamp!('mise_migration')
      end
    end
  end
end
