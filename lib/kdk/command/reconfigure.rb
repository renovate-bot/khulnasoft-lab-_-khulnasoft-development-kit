# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk reconfigure` command execution
    class Reconfigure < BaseCommand
      def run(_args = [])
        unless run_rake('kdk-config.mk')
          out.error("Failed to generate kdk.config.yml, check your kdk.yml.")
          false
        end

        # already done in `rake kdk-config.mk`
        ENV['SKIP_GENERATE_KDK_CONFIG_MK'] = '1'

        diff = diff_config
        success = run_rake(:reconfigure)

        if success
          out.success('Successfully reconfigured!')

          unless diff.empty?
            out.puts
            out.puts diff unless diff.empty?
          end
        else
          out.error('Failed to reconfigure.')
          display_help_message
        end

        success
      rescue Support::Rake::TaskWithLogger::LoggerError => e
        e.print!
        false
      end

      private

      def diff_config
        Diagnostic::Configuration.new.config_diff
      end
    end
  end
end
