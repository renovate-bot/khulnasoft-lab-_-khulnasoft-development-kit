# frozen_string_literal: true

desc 'Preflight checks for dependencies'
task 'preflight-checks' do
  checker = KDK::Dependencies::Checker.new(preflight: true)
  checker.check_all

  unless checker.error_messages.empty?
    warn checker.error_messages
    raise 'Preflight checks failed'
  end
end

desc 'Preflight Update checks'
task 'preflight-update-checks' do
  postgresql = KDK::Postgresql.new
  if postgresql.installed? && postgresql.upgrade_needed?
    message = <<~MESSAGE
      PostgreSQL data directory is version #{postgresql.current_version} and must be upgraded to version #{postgresql.class.target_version} before KDK can be updated.
    MESSAGE

    KDK::Output.warn(message)

    if ENV['PG_AUTO_UPDATE']
      KDK::Output.warn('PostgreSQL will be auto-updated in 10 seconds. Hit CTRL-C to abort.')
      Kernel.sleep 10
    else
      prompt_response = KDK::Output.prompt("This will run 'support/upgrade-postgresql' to back up and upgrade the PostgreSQL data directory. Are you sure? [y/N]").match?(/\Ay(?:es)*\z/i)
      next unless prompt_response
    end

    postgresql.upgrade

    KDK::Output.success("Successfully ran 'support/upgrade-postgresql' script!")
  end
end

namespace :update do
  desc 'Tool versions update'
  task 'tool-versions' do
    KDK::ToolVersionsUpdater.new.run if KDK.config.mise.enabled? || !KDK.config.asdf.opt_out?
  end
end
