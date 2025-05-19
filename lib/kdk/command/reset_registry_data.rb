# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk reset-registry-data` command execution
    class ResetRegistryData < BaseCommand
      def run(_ = [])
        return false unless continue?

        execute
      end

      private

      def continue?
        KDK::Output.warn("We're about to remove Container Registry PostgreSQL data.")

        return true unless KDK::Output.interactive?

        KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      end

      def execute
        manager = KDK::RegistryDatabaseManager.new(KDK.config)
        manager.reset_registry_database
      end
    end
  end
end
