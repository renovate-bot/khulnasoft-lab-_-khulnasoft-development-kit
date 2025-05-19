# frozen_string_literal: true

require 'socket'
require 'fileutils'

require_relative '../kdk'

module Support
  # Bootstrap KhulnaSoft rails environment
  class BootstrapRails
    # The log file should be in the "support" folder, not in "suppport/lib"
    LOG_FILE = '../bootstrap-rails.log'

    def execute
      if config.geo.secondary?
        KDK::Output.info("Exiting as we're a Geo secondary.")
        exit
      end

      KDK::Output.abort('Cannot connect to PostgreSQL.') unless postgresql.ready?
      FileUtils.rm_f(LOG_FILE)

      bootstrap_main_db && bootstrap_ci_db && bootstrap_sec_db && bootstrap_embedding_db
    end

    private

    def bootstrap_main_db
      if_db_not_found('khulnasofthq_development') do
        run_tasks(%w[db:drop db:create khulnasoft:db:configure]) &&
          set_feature_flags
      end
    end

    def set_feature_flags
      # Nothing set right now
      true
    end

    def bootstrap_ci_db
      return if !config.khulnasoft.rails.databases.ci.__enabled || config.khulnasoft.rails.databases.ci.__use_main_database

      if_db_not_found('khulnasofthq_development_ci') do
        run_tasks('dev:copy_db:ci')
      end
    end

    def bootstrap_sec_db
      return if !config.khulnasoft.rails.databases.sec.__enabled || config.khulnasoft.rails.databases.sec.__use_main_database

      if_db_not_found('khulnasofthq_development_sec') do
        run_tasks('dev:copy_db:sec')
      end
    end

    def bootstrap_embedding_db
      return unless config.khulnasoft.rails.databases.embedding.enabled

      if_db_not_found('khulnasofthq_development_embedding') do
        run_tasks('db:reset:embedding')
      end
    end

    def run_tasks(*tasks)
      test_gitaly_up!

      rake = KDK::Execute::Rake.new(*tasks)
      unless rake.execute_in_khulnasoft(retry_attempts: 3).success?
        KDK::Output.abort <<~MESSAGE
          The rake task '#{tasks.join(' ')}' failed. Trying to run it again!
        MESSAGE
      end

      true
    end

    def if_db_not_found(db)
      if postgresql.db_exists?(db)
        KDK::Output.info("#{db} exists, nothing to do here.")
        true
      else
        yield
      end
    end

    def postgresql
      @postgresql ||= KDK::Postgresql.new
    end

    def config
      KDK.config
    end

    def test_gitaly_up!
      try_connect!(config.praefect? ? 'praefect' : 'gitaly')
    end

    def try_connect!(service)
      print "Waiting for #{service} to boot"

      sleep_time = 0.1
      repeats = 100

      repeats.times do
        sleep sleep_time
        print '.'

        begin
          UNIXSocket.new("#{service}.socket").close
          KDK::Output.puts 'OK'

          return
        rescue Errno::ENOENT, Errno::ECONNREFUSED
        end
      end

      KDK::Output.error " failed to connect to #{service} after #{repeats * sleep_time}s"
      KDK::Output.puts(stderr: true)
      system('grep', "#{service}.1", LOG_FILE)

      abort
    end
  end
end
