# frozen_string_literal: true

require 'forwardable'

module KDK
  module TaskHelpers
    # Class to work with database migrations on gitlab-rails
    class RailsMigration
      extend Forwardable

      MAIN_TASKS = %w[db:migrate db:test:prepare].freeze
      GEO_TASKS = %w[db:migrate:geo db:test:prepare:geo].freeze

      def_delegators :postgresql, :in_recovery?

      def migrate
        tasks = migrate_tasks

        return true if migrate_tasks.empty?

        display_migrate_message(tasks.keys)
        rake(tasks.values.flatten)
      end

      private

      def migrate_tasks
        tasks = {}
        tasks['rails'] = MAIN_TASKS unless geo_secondary? || in_recovery?
        tasks['Geo'] = GEO_TASKS if geo_secondary?

        tasks
      end

      def display_migrate_message(tasks)
        str = tasks.join(' and ')

        KDK::Output.divider
        KDK::Output.puts("Processing gitlab #{str} DB migrations")
        KDK::Output.divider
      end

      def rake(tasks)
        KDK::Execute::Rake.new(*tasks).execute_in_gitlab.success?
      end

      def geo_secondary?
        KDK.config.geo.secondary?
      end

      def geo?
        KDK.config.geo?
      end

      def postgresql
        @postgresql ||= KDK::Postgresql.new
      end
    end
  end
end
