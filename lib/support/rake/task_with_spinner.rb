# frozen_string_literal: true

begin
  require 'tty-spinner'
  require 'tty-screen'
rescue LoadError
end

module Support
  module Rake
    module TaskWithSpinner
      class << self
        attr_accessor :spinner_manager, :screen_cols
      end

      TaskSkippedError = Class.new(StandardError)

      def self.set_screen_cols
        self.screen_cols = TTY::Screen.cols
      end

      def self.set_screen_cols_on_window_size_change
        Signal.trap('WINCH') { set_screen_cols }
      end

      def enable_spinner!
        return unless KDK::Output.interactive?
        return unless defined?(TTY::Spinner)

        Support::Rake::TaskWithSpinner.set_screen_cols
        Support::Rake::TaskWithSpinner.set_screen_cols_on_window_size_change

        @enable_spinner = true
      end

      def invoke(...)
        if @enable_spinner
          TaskWithSpinner.spinner_manager&.stop
          TaskWithSpinner.spinner_manager = ::TTY::Spinner::Multi.new(
            spinner_name,
            success_mark: "\e[32m#{TTY::Spinner::TICK}\e[0m",
            error_mark: "\e[31m#{TTY::Spinner::CROSS}\e[0m",
            format: :dots,
            # $stderr is overwritten in TaskWithLogger
            output: STDERR # rubocop:disable Style/GlobalStdStream
          )
        end

        super
      ensure
        TaskWithSpinner.spinner_manager&.stop if @enable_spinner
      end

      def execute(...)
        @kdk_execute_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        spinner = nil
        if TaskWithSpinner.spinner_manager && show_spinner?
          logger = Support::Rake::TaskLogger.current
          thread = Thread.new do
            Support::Rake::TaskLogger.set_current!(logger)
            sleep 0.001
            next if @skipped || TaskWithSpinner.spinner_manager.top_spinner.message == spinner_name

            spinner = TaskWithSpinner.spinner_manager.register spinner_name(':recent_line')
            spinner.update(recent_line: '')
            spinner.on(:spin, &on_spin(logger, spinner))
            spinner.auto_spin
          end
        end

        super
      rescue StandardError => e
        spinner&.update(recent_line: '')
        spinner&.error(execution_duration_message)
        raise e unless e.instance_of?(TaskSkippedError)
      else
        spinner&.update(recent_line: '')
        spinner&.success(execution_duration_message)
      ensure
        thread&.join
      end

      def skip!
        @skipped = true
        raise TaskSkippedError
      end

      private

      # rubocop:disable Style/AsciiComments -- Real-world example
      # "└── ⠏ Run "
      # rubocop:enable Style/AsciiComments -- Real-world example
      LABEL_PREFIX_LENGTH = 10

      def on_spin(logger, spinner)
        proc do
          line_limit = Support::Rake::TaskWithSpinner.screen_cols - LABEL_PREFIX_LENGTH - name.length
          recent_line = logger.recent_line&.slice(0, line_limit)

          if recent_line && @previous_recent_line != recent_line
            @previous_recent_line = recent_line
            recent_line = KDK::Output.wrap_in_color(recent_line, KDK::Output::COLOR_CODE_BRIGHT_BLACK)
            spinner.update(recent_line: recent_line.prepend(' '))
          end
        end
      end

      # A task without action (i.e. do ... end block) will finish
      # instantly after all dependencies have finished, so we don't want
      # to show a spinner for it.
      def show_spinner?
        !actions.empty?
      end

      def spinner_name(appendix = '')
        ":spinner #{comment || name}#{appendix}"
      end

      def execution_duration_message
        duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - (@kdk_execute_start || 0)
        "[#{format_duration(duration)}]"
      end

      def format_duration(seconds)
        return "#{(seconds * 1000).floor}ms" if seconds < 1
        return "#{seconds.round}s" if seconds < 60

        "#{(seconds / 60).floor}m #{seconds.round % 60}s"
      end
    end
  end
end
