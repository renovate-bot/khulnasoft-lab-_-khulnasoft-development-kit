# frozen_string_literal: true

module KDK
  module Diagnostic
    class PendingMigrations < Base
      TITLE = 'Database Migrations'

      def success?
        applied_migration_versions.all? do |versions|
          (existing_migration_versions - versions).empty?
        end
      end

      def detail
        return if success?

        <<~MESSAGE
          There are pending database migrations.  To update your database, run:

            (kdk start db && cd #{config.gitlab.dir} && #{config.kdk_root}/support/bundle-exec rails db:migrate)
        MESSAGE
      end

      private

      def existing_migration_versions
        @existing_migration_versions ||= Dir["#{config.gitlab.dir}/db/schema_migrations/*"].map { |path| File.basename(path) }
      end

      def applied_migration_versions
        suffixes = config.gitlab.rails.databases.attributes.keys.filter_map do |key|
          db = config.gitlab.rails.databases[key]

          "_#{key}" if db.__enabled && !db[:use_main_database]
        end
        suffixes.push('') # main

        @applied_migration_versions ||=
          suffixes.map { |suffix| select_versions_for("gitlabhq_development#{suffix}") }
      end

      def select_versions_for(database)
        args = ['--no-align', '--tuples-only', '--command', 'select version from schema_migrations']
        command = *KDK::Postgresql.new.psql_cmd(args, database: database)
        KDK::Shellout.new(command).execute(display_output: false).read_stdout.split("\n")
      end
    end
  end
end
