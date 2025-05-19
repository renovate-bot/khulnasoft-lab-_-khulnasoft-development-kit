# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk version` command execution
    class Version < BaseCommand
      # Allow invalid kdk.yml.
      def self.validate_config?
        false
      end

      def run(_ = [])
        KDK::Output.puts("#{KDK::VERSION} (#{version.current_commit.sha})")
        diff_message = version.diff_message
        KDK::Output.puts(diff_message) if diff_message

        true
      end

      private

      def version
        @version ||= ::KDK::VersionChecker.new(
          service_path: KDK.root
        )
      end
    end
  end
end
