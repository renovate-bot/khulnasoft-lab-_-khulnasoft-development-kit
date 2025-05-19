# frozen_string_literal: true

module KDK
  class Postgresql
    def self.target_version
      Gem::Version.new(Asdf::ToolVersions.new.default_version_for('postgres'))
    end

    def self.target_version_major
      target_version.canonical_segments[0]
    end

    def initialize(config = KDK.config)
      @config = config
    end

    def psql_cmd(args, database: default_database)
      pg_cmd(args, database: database).flatten
    end

    def current_data_dir
      @current_data_dir ||= postgresql_config.data_dir
    end

    def current_version
      @current_version ||= begin
        raise "PG_VERSION not found in #{pg_version_file}. Is PostgreSQL initialized?" unless installed?

        version = pg_version_file.read.to_f

        # After PostgreSQL 9.6, PG_VERSION uses a single integer (10, 11, 12, etc.)
        version >= 10 ? version.to_i : version
      end
    end

    def installed?
      pg_version_file.exist?
    end

    def ready?(try_times: 10, interval: 1, quiet: false)
      last_error = nil
      cmd = pg_cmd(database: 'template1')

      try_times.times do |i|
        sleep(interval) if i.positive?

        shellout = Shellout.new(cmd).tap(&:try_run)
        last_error = shellout.read_stderr

        return true if shellout.success?
      end

      KDK::Output.error(last_error) unless quiet
      false
    end

    def use_tcp?
      !postgresql_config.host.start_with?('/')
    end

    def upgrade_needed?(target_version = self.class.target_version_major)
      current_version < target_version.to_f
    end

    def upgrade
      cmd = 'support/upgrade-postgresql'

      Shellout.new(cmd).stream
    end

    def db_exists?(dbname)
      Shellout.new(pg_cmd(database: dbname)).tap(&:try_run).success?
    end

    def createdb(*args)
      cmd = pg_cmd(*args, program: 'createdb')

      Shellout.new(cmd).run
    end

    def in_recovery?
      cmd = pg_cmd('--no-psqlrc', '--tuples-only',
        database: 'postgres',
        command: 'SELECT pg_is_in_recovery();')

      Shellout.new(cmd).try_run.downcase.strip.chomp == 't'
    end

    private

    attr_reader :config

    def base_postgresql_config
      @base_postgresql_config ||= config.postgresql
    end

    def postgresql_config
      @postgresql_config ||= base_postgresql_config
    end

    def pg_version_file
      @pg_version_file ||= current_data_dir.join('PG_VERSION')
    end

    def pg_cmd(*args, program: 'psql', database: nil, command: nil)
      cmd = [base_postgresql_config.bin_dir.join(program).to_s]
      cmd << "--host=#{postgresql_config.dir}"
      cmd << "--port=#{postgresql_config.port}"
      cmd << "--dbname=#{database}" if database
      cmd << "--command=#{command}" if command

      cmd + args
    end

    def default_database
      'khulnasofthq_development'
    end
  end
end
