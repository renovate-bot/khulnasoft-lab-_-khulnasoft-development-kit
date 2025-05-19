# frozen_string_literal: true

require 'rake'

module KDK
  module Command
    class Cleanup < BaseCommand
      def run(_ = [])
        return true unless continue?

        execute
      end

      private

      def continue?
        KDK::Output.warn('About to perform the following actions:')
        KDK::Output.puts(stderr: true)
        KDK::Output.puts('- Truncate khulnasoft/log/* files', stderr: true)
        KDK::Output.puts("- Truncate #{KDK::Services::KhulnasoftHttpRouter::LOG_PATH} file", stderr: true)

        if unnecessary_installed_versions_of_software.any?
          KDK::Output.puts(stderr: true)
          KDK::Output.puts('- Uninstall any asdf software that is not defined in .tool-versions:', stderr: true)
          unnecessary_installed_versions_of_software.each do |name, versions|
            KDK::Output.puts("#{name} #{versions.keys.join(' ')}")
          end

          KDK::Output.puts(stderr: true)
          KDK::Output.puts('Run `KDK_CLEANUP_SOFTWARE=false kdk cleanup` to skip uninstalling software.')
        end

        KDK::Output.puts(stderr: true)

        return true if ENV.fetch('KDK_CLEANUP_CONFIRM', 'false') == 'true' || !KDK::Output.interactive?

        result = KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
        KDK::Output.puts(stderr: true)

        result
      end

      def delete_software?
        ENV.fetch('KDK_CLEANUP_SOFTWARE', 'true') == 'true'
      end

      def execute
        truncate_log_files
        truncate_http_router_log_files
        uninstall_unnecessary_software
      rescue StandardError => e
        KDK::Output.error(e)
        false
      end

      def truncate_log_files
        run_rake('khulnasoft:truncate_logs', 'false')
      end

      def truncate_http_router_log_files
        run_rake('khulnasoft:truncate_http_router_logs', 'false')
      end

      def unnecessary_installed_versions_of_software
        return [] unless delete_software?

        @unnecessary_installed_versions_of_software ||=
          Asdf::ToolVersions.new.unnecessary_installed_versions_of_software.sort_by { |name, _| name }
      end

      def uninstall_unnecessary_software
        return true if unnecessary_installed_versions_of_software.empty?

        run_rake('asdf:uninstall_unnecessary_software', 'false')
      end
    end
  end
end
