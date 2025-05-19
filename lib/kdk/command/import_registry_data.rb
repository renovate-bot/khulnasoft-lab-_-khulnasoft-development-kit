# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk import-registry-data` command execution
    class ImportRegistryData < BaseCommand
      def run(_ = [])
        return false unless continue?

        execute
      end

      private

      def continue?
        if !config.dig('registry', 'read_only_maintenance_enabled') || config.dig('registry', 'database', 'enabled')
          KDK::Output.error("registry.database.enabled must be set to false and registry.read_only_maintenance_enabled must be set to true to run the registry import")
          false
        else

          KDK::Output.warn("We're about to import the data in your container registry to the new metadata database registry. Once on the metadata registry you must continue to use it. Disabling it after this point causes the registry to lose visibility on all images written to it while the database was active.")

          return true unless KDK::Output.interactive?

          KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
        end
      end

      def execute
        manager = KDK::RegistryDatabaseManager.new(KDK.config)
        manager.reset_registry_database
        manager.import_registry_data
      end
    end
  end
end
