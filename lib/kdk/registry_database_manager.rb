# frozen_string_literal: true

module KDK
  class RegistryDatabaseManager
    def initialize(config)
      @config = config
    end

    def reset_registry_database
      stop_runit_services
      sleep(2)
      start_postgresql_service
      sleep(2)
      drop_database('registry_dev')
      recreate_database('registry_dev')
      migrate_database
    end

    def import_registry_data
      shellout(kdk_root.join('support', 'import-registry').to_s)
    end

    private

    attr_reader :config

    def kdk_root
      config.kdk_root
    end

    def start_postgresql_service
      KDK::Command::Start.new.run(['postgresql', '--quiet'])
    end

    def stop_runit_services
      KDK::Command::Stop.new.run([])
    end

    def drop_database(database_name)
      shellout(psql_cmd("drop database #{database_name}"))
    end

    def recreate_database(database_name)
      shellout(psql_cmd("create database #{database_name}"))
    end

    def migrate_database
      shellout(kdk_root.join('support', 'migrate-registry').to_s)
    end

    def psql_cmd(command)
      KDK::Postgresql.new(config).psql_cmd(['-c'] + [command])
    end

    def shellout(command)
      sh = Shellout.new(command, chdir: kdk_root)
      sh.stream
      sh.success?
    end
  end
end
