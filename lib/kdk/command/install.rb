# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk install` command execution
    #
    # This command accepts the following parameters:
    # - khulnasoft_repo=<url to repository> (defaults to: "https://github.com/khulnasoft-lab/khulnasoft")
    # - telemetry_enabled=<true|false> (defaults to: false)
    class Install < BaseCommand
      def run(args = [])
        args.each do |arg|
          case arg
          when /^telemetry_enabled=(true|false)$/
            KDK::Telemetry.update_settings(Regexp.last_match(1) == 'true' ? 'y' : 'n')
          end
        end

        result = KDK.make('install', *args)

        unless result.success?
          KDK::Output.error('Failed to install.', result.stderr_str)
          display_help_message
        end

        Announcements.new.cache_all if result.success?

        result.success?
      end
    end
  end
end
