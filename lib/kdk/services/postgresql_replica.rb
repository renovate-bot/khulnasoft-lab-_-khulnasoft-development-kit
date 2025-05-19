# frozen_string_literal: true

module KDK
  module Services
    # PostgreSQL server replica
    class PostgresqlReplica < Base
      def name
        'postgresql-replica'
      end

      def command
        %(support/postgresql-signal-wrapper #{postgresql_bin} -D #{postgresql_data_dir} -k #{postgresql_replica_dir} -h '#{postgresql_active_host}' -c max_connections=#{max_connections})
      end

      def enabled?
        config.postgresql.replica?
      end

      private

      def postgresql_bin
        config.postgresql.bin
      end

      def postgresql_replica_dir
        config.postgresql.replica.root_directory
      end

      def postgresql_data_dir
        config.postgresql.replica.data_directory
      end

      def postgresql_active_host
        config.postgresql.__active_host
      end

      def max_connections
        config.postgresql.max_connections
      end
    end
  end
end
