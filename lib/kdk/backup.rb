# frozen_string_literal: true

require 'pathname'

module KDK
  class Backup
    SourceFileOutsideOfGdk = Class.new(StandardError)
    SourceFileDoesntExist = Class.new(StandardError)

    attr_reader :source_file

    def self.backup_root
      KDK.root.join('.backups')
    end

    def initialize(source_file)
      @source_file = Pathname.new(source_file.to_s).expand_path

      validate!
    end

    def backup!(advise: true)
      ensure_backup_directory_exists
      make_backup_of_source_file
      advise_user_backup if advise

      true
    end

    def restore!(advise: true)
      return false unless destination_file.exist?

      restore_backup
      advise_user_restore if advise

      true
    end

    def destination_file
      @destination_file ||= backup_root.join("#{relative_source_file.to_s.gsub('/', '__')}.#{Time.now.strftime('%Y%m%d%H%M%S')}")
    end

    def relative_source_file
      @relative_source_file ||= source_file.relative_path_from(KDK.root)
    end

    def recover_cmd_string
      <<~CMD
        cp -f '#{destination_file}' \\
        '#{source_file}'
      CMD
    end

    private

    def relative_destination_file
      @relative_destination_file ||= destination_file.relative_path_from(KDK.root)
    end

    def validate!
      raise SourceFileDoesntExist unless source_file.exist?
      raise SourceFileOutsideOfGdk unless source_file.to_s.start_with?(KDK.root.to_s)

      true
    end

    def backup_root
      @backup_root ||= self.class.backup_root
    end

    def ensure_backup_directory_exists
      backup_root.mkpath
    end

    def advise_user_backup
      KDK::Output.info("A backup of '#{relative_source_file}' has been made at '#{relative_destination_file}'.")
    end

    def advise_user_restore
      KDK::Output.info("Backup '#{relative_destination_file}' has been restored to '#{relative_source_file}'.")
    end

    def make_backup_of_source_file
      FileUtils.mv(source_file.to_s, destination_file.to_s)
    end

    def restore_backup
      FileUtils.cp(destination_file.to_s, source_file.to_s)
    end
  end
end
