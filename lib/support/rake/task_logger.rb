# frozen_string_literal: true

require 'fileutils'

module Support
  module Rake
    class TaskLogger
      def self.set_current!(logger)
        Thread.current[:kdk_task_logger] = logger
        logger&.create_latest_symlink!(@symlink_mutex ||= Mutex.new)
      end

      def self.current
        Thread.current[:kdk_task_logger]
      end

      def self.start_time
        @start_time ||= Time.now
      end

      def self.from_task(task)
        new("#{TaskLogger.logs_dir}/#{task.name.gsub(%r{[:\s/.]+}, '-')}.log")
      end

      def self.logs_dir
        "#{KDK.root}/log/kdk/rake-#{TaskLogger.start_time.strftime('%Y-%m-%d_%H-%M-%S_%L')}"
      end

      attr_reader :file_path, :recent_line

      def initialize(file_path)
        @file_path = Pathname(file_path)

        create_logs_dir!
      end

      def file
        @file ||= File.open(@file_path, 'w').tap { |file| file.sync = true }
      end

      # Input must have at least one valid char. This excludes newlines and separators-only lines.
      INPUT_REGEXP = /\w/
      # Rails noise.
      IGNORE_INPUT_NOISE = 'DEPRECATION WARNING'

      private_constant :INPUT_REGEXP, :IGNORE_INPUT_NOISE

      def record_input(string)
        return unless string

        recent_line = string
          .split("\n")
          .reverse_each
          .find { |line| !line.include?(IGNORE_INPUT_NOISE) && INPUT_REGEXP.match?(line) }

        @recent_line = recent_line if recent_line
      end

      def cleanup!(delete: true)
        return if @file&.closed?

        File.delete(@file_path) if @file&.size === 0 && delete
        @file&.close
      end

      def tail(max_lines: 25, exclude_gems: true)
        f = File.read(@file_path)
        original_lines = f.split("\n")
        lines = original_lines.reject { |l| exclude_gems && l.include?('/ruby/gems/') }
        needs_log_link = lines.length > max_lines || original_lines.length > lines.length
        lines = lines.last(max_lines)

        lines.push("", "See #{@file_path} for the full log.") if needs_log_link

        lines.join("\n")
      end

      def create_latest_symlink!(mutex)
        mutex.synchronize do
          link_name = "#{KDK.root}/log/kdk/rake-latest"
          next if File.symlink?(link_name) && File.readlink(link_name) == TaskLogger.logs_dir

          FileUtils.ln_sf(TaskLogger.logs_dir, link_name)
        end
      end

      private

      def create_logs_dir!
        file_path.parent.mkpath
      end
    end
  end
end

# Inspired by https://stackoverflow.com/a/16184325/6403374
# but adjusted so we can use it with our own task logger
#
# We use __send__ to proxy IO function on Kernel.
# rubocop:disable KhulnasoftSecurity/PublicSend
module Kernel
  [:printf, :p, :print, :puts, :warn].each do |method|
    name = "__#{method}__"

    alias_method name, method

    define_method(method) do |*args|
      logger = Support::Rake::TaskLogger.current
      return __send__(name, *args) unless logger

      kdk_rake_log_lock.synchronize do
        $stdout = logger.file
        $stderr = logger.file
        __send__(name, *args)
      ensure
        $stdout = STDOUT
        $stderr = STDERR
      end
    end
  end

  private

  def kdk_rake_log_lock
    @kdk_rake_log_lock ||= Mutex.new
  end
end
# rubocop:enable KhulnasoftSecurity/PublicSend
