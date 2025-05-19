# frozen_string_literal: true

require 'time'

module KDK
  module ReminderHelper
    REMINDER_DIR_NAME = '.kdk_reminders'

    def self.should_run_reminder?(reminder_type, days_interval = 5)
      cache_path = reminder_cache_path(reminder_type)

      last_run = File.exist?(cache_path) ? Time.parse(File.read(cache_path)) : nil
      !last_run || (Time.now - last_run) >= (days_interval * 24 * 60 * 60)
    end

    def self.update_reminder_timestamp!(reminder_type)
      File.write(reminder_cache_path(reminder_type), Time.now.iso8601)
    end

    def self.reminder_cache_path(reminder_type)
      path = KDK.config.__cache_dir.join(REMINDER_DIR_NAME, reminder_type)
      FileUtils.mkdir_p(path.dirname)

      path
    end

    private_class_method :reminder_cache_path
  end
end
