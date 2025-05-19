# frozen_string_literal: true

require 'time'

module KDK
  module Command
    # Switches to a branch in the monolith and sets up the environment for it.
    class Switch < BaseCommand
      def run(args = [])
        branch = args.pop

        unless branch
          out.warn('Usage: kdk switch [BRANCH_NAME]')
          return false
        end

        # Don't save config after this
        config.bury!('khulnasoft.default_branch', branch)

        success = KDK::Hooks.with_hooks(config.kdk.update_hooks, 'kdk switch') do
          run_rake('update_branch', branch)
        end

        unless success
          KDK::Output.error('Failed to switch branches.', report_error: false)
          display_help_message
          return false
        end

        color_branch = out.wrap_in_color(branch, Output::COLOR_CODE_YELLOW)
        KDK::Output.success("Switched to #{color_branch}.")

        true
      rescue Support::Rake::TaskWithLogger::LoggerError => e
        e.print!
        false
      end
    end
  end
end
