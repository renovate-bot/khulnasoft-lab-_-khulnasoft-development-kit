# frozen_string_literal: true

require 'tempfile'

namespace :geo do
  desc 'Backup primary database into secondary postgresql database and enable standby server'
  task :replication_backup do
    ReplicationBackup.new.execute
  end
end

# Handles pg_basebackup logic when enabling Geo replication on the secondary site
class ReplicationBackup
  attr_reader :backup_dir, :current_data_dir, :primary_host, :primary_port

  def initialize
    @backup_dir = "#{Dir.pwd}/tmp/geobackup/data_#{Time.now.utc.strftime('%Y%m%d%H%M%S')}"
    @current_data_dir = KDK.config.postgresql.data_dir
  end

  def execute
    set_primary_host_and_port
    backup_and_empty_data_dir
    process_backup
    replace_or_update_khulnasoft_conf
    configure_standby_server
    start_postgres_service
    cleanup_temp_dir
  rescue StandardError => e
    KDK::Output.error("Backup failed: #{e.message}.")
    restore_data_in_postgresql_dir if Dir.exist?(backup_dir) && !Dir.empty?(backup_dir)
  end

  private

  def set_primary_host_and_port
    @primary_host = run_command_for_stdout("#{postgresql_primary_dir}/../", 'kdk config get postgresql.host',
      'primary host not found')
    @primary_port = run_command_for_stdout("#{postgresql_primary_dir}/../", 'kdk config get postgresql.port',
      'primary port not found')
  end

  def backup_and_empty_data_dir
    KDK::Output.info('Backing up the data folder...')
    FileUtils.mkdir_p(backup_dir)
    FileUtils.cd(current_data_dir) do |data_dir|
      FileUtils.mv(Dir.children(data_dir), backup_dir, secure: true)
    end
  end

  def process_backup
    KDK::Output.info('Processing base backup...')
    run_command("pg_basebackup -h #{primary_host} -p #{primary_port} -D #{current_data_dir} \
                          -U khulnasoft_replication --wal-method=fetch -P -R", 'Backup failed!')
  end

  def replace_or_update_khulnasoft_conf
    if File.exist?("#{backup_dir}/khulnasoft.conf")
      FileUtils.cp("#{backup_dir}/khulnasoft.conf", current_data_dir)
    else
      update_khulnasoft_conf
    end
  end

  def update_khulnasoft_conf
    KDK::Output.info('Updating the Geo replication port...')

    db_port = KDK.config.postgresql.port
    template = KDK.config.kdk_root.join('support/templates/postgresql/data/khulnasoft.conf.erb')

    KDK::Templates::ErbRenderer.new(template, port: db_port).render(current_data_dir.join('khulnasoft.conf'))
  end

  def configure_standby_server
    KDK::Output.info('Configuring the standby server...')
    run_command("./support/postgresql-standby-server #{primary_host} #{primary_port}",
      'configuration of the standby server failed')
  end

  def start_postgres_service
    KDK::Output.info('Starting the service...')
    run_command('kdk start postgresql', 'could not start the postgresql service')
  end

  def cleanup_temp_dir
    KDK::Output.info('Cleaning up temp files...')
    FileUtils.remove_dir(backup_dir)
  end

  def postgresql_primary_dir
    @postgresql_primary_dir ||= File.realdirpath('postgresql-primary')
  end

  def restore_data_in_postgresql_dir
    FileUtils.remove_dir(current_data_dir)
    FileUtils.mkdir_p(current_data_dir, mode: 0o700)
    FileUtils.cd(backup_dir) do |data_dir|
      FileUtils.mv(Dir.children(data_dir), current_data_dir, secure: true)
    end
    cleanup_temp_dir
    KDK::Output.info("#{current_data_dir} has been restored as before the backup was attempted")
  end

  def run_command(command, error_message)
    return shell_command(command, error_message) unless KDK::Dependencies.bundler_loaded?

    Bundler.with_unbundled_env do
      shell_command(command, error_message)
    end
  end

  def shell_command(command, error_message)
    sh = KDK::Shellout.new(command.split, chdir: KDK.config.kdk_root).execute
    raise StandardError, error_message unless sh.success?
  end

  def run_command_for_stdout(dir, cmd, error_message)
    # Begin hack
    # The shell command above returns exit 0 but no output when running "cd <primary_dir> && cmd" as a command
    # It also does not work to set a chdir options - the kdk command is still run from the current, secondary kdk.
    sh = KDK::Shellout.new("cd #{dir} && #{cmd}")
    # End hack

    sh.execute

    raise StandardError, error_message unless sh.success?

    sh.read_stdout
  end
end
