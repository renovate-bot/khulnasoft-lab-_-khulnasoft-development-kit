# frozen_string_literal: true

require_relative '../../kdk'

module KDK
  module Command
    # Truncate legacy database tables to remove stale data in the CI decomposed database
    class TruncateLegacyTables < BaseCommand
      FLAG_FILE = "#{KDK.root}/.cache/.truncate_tables".freeze

      def run(_args = [])
        unless truncation_needed?
          KDK::Output.info('Truncation not required as your KDK is up-to-date.')
          return true
        end

        ensure_databases_running
        truncate_tables
        true
      end

      def truncation_needed?
        ci_database_enabled? && !geo_secondary? && !flag_file_exists?
      end

      private

      def ci_database_enabled?
        KDK.config.khulnasoft.rails.databases.ci.enabled
      end

      def geo_secondary?
        KDK.config.geo.secondary?
      end

      def flag_file_exists?
        File.exist?(FLAG_FILE)
      end

      def ensure_databases_running
        KDK::Command::Start.new.run(['rails-migration-dependencies'])
      end

      def truncate_tables
        KDK::Output.notice('Ensuring legacy data in main & ci databases are truncated.')

        if execute_truncation_tasks
          report_success
          create_flag_file
        else
          report_failure
        end
      end

      def execute_truncation_tasks
        rake_tasks = %w[
          khulnasoft:db:lock_writes
          khulnasoft:db:truncate_legacy_tables:main
          khulnasoft:db:truncate_legacy_tables:ci
          khulnasoft:db:unlock_writes
        ].freeze

        KDK::Execute::Rake.new(*rake_tasks).execute_in_khulnasoft.success?
      end

      def report_success
        KDK::Output.success('Legacy table truncation completed successfully.')
      end

      def create_flag_file
        FileUtils.mkdir_p(File.dirname(FLAG_FILE))
        FileUtils.touch(FLAG_FILE)
      end

      def report_failure
        KDK::Output.error('Legacy table truncation failed.')
      end
    end
  end
end
