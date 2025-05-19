# frozen_string_literal: true

module KDK
  module Output
    COLOR_CODE_RED = '31'
    COLOR_CODE_GREEN = '32'
    COLOR_CODE_YELLOW = '33'
    COLOR_CODE_BLUE = '34'
    COLOR_CODE_BRIGHT_BLACK = '90'

    COLORS = {
      red: COLOR_CODE_RED,
      green: COLOR_CODE_GREEN,
      yellow: COLOR_CODE_YELLOW,
      blue: COLOR_CODE_BLUE,
      magenta: '35',
      cyan: '36',
      bright_red: '31;1',
      bright_green: '32;1',
      bright_yellow: '33;1',
      bright_blue: '34;1',
      bright_magenta: '35;1',
      bright_cyan: '36;1'
    }.freeze

    ICONS = {
      info: "\u2139\ufe0f ",    # requires an extra space
      success: "\u2705\ufe0f",
      warning: "\u26A0\ufe0f ", # requires an extra space
      error: "\u274C\ufe0f",
      debug: "\u26CF\ufe0f " # requires an extra space
    }.freeze

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def ensure_utf8(str)
        return '' if str.nil?
        return str unless str.is_a?(String)

        str = force_encode_utf8(str)
        return str if str.valid_encoding?

        str.encode('UTF-8', invalid: :replace, undef: :replace)
      end

      # Borrowed from https://github.com/khulnasoft-lab/khulnasoft/-/blob/0a06e1dcb2474f866e2f335cee2d0cb3c6886db3/lib/khulnasoft/encoding_helper.rb#L165-172
      def force_encode_utf8(message)
        return message if message.encoding == Encoding::UTF_8 && message.valid_encoding?

        message = message.dup if message.respond_to?(:frozen?) && message.frozen?

        message.force_encoding('UTF-8')
      end

      def color(index)
        COLORS.values[index % COLORS.size]
      end

      def ansi(code)
        "\e[#{code}m"
      end

      def reset_color
        ansi(0)
      end

      def wrap_in_color(message, color_code)
        return message unless colorize?

        "#{ansi(color_code)}#{ensure_utf8(message)}#{reset_color}"
      end

      def format_log(log_level, color_code, message)
        message = ensure_utf8(message)

        "#{icon(log_level)}#{wrap_in_color(log_level.upcase, color_code)}: #{message}"
      end

      def stdout_handle
        return Support::Rake::TaskLogger.current.file if Support::Rake::TaskLogger.current

        $stdout.tap { |handle| handle.sync = true }
      end

      def stderr_handle
        return Support::Rake::TaskLogger.current.file if Support::Rake::TaskLogger.current

        $stderr.tap { |handle| handle.sync = true }
      end

      def print(message = nil, stderr: false)
        output = stderr ? stderr_handle : stdout_handle

        output.print(ensure_utf8(message))
      rescue IOError
      end

      def puts(message = nil, stderr: false)
        output = stderr ? stderr_handle : stdout_handle

        output.puts(ensure_utf8(message))
      end

      def divider(symbol: '-', length: 80, stderr: false)
        puts(symbol * length, stderr: stderr)
      end

      def notice(message)
        puts(notice_format(message))
      end

      def notice_format(message)
        "=> #{message}"
      end

      def info(message)
        puts(icon(:info) + message)
      end

      def warn(message)
        puts(format_log(:warning, COLOR_CODE_YELLOW, message), stderr: true)
      end

      def debug(message)
        return unless KDK.config.kdk.__debug?

        puts(format_log(:debug, COLOR_CODE_BLUE, message), stderr: true)
      end

      def format_error(message)
        format_log(:error, COLOR_CODE_RED, message)
      end

      def error(message, exception = nil, report_error: true)
        Telemetry.capture_exception(exception || message) if report_error

        puts(format_error(message), stderr: true)
      end

      def abort(message, exception = nil, report_error: true)
        Telemetry.capture_exception(exception || message) if report_error

        Kernel.abort(format_error(message))
      end

      def success(message)
        puts(icon(:success) + message)
      end

      def icon(code)
        return '' unless colorize?

        "#{ICONS[code]} "
      end

      def interactive?
        $stdin.isatty
      end

      def colorize?
        interactive? && ENV.fetch('NO_COLOR', '').empty?
      end

      def prompt(message)
        Kernel.print("#{message}: ")
        $stdout.flush

        raise 'Interactive terminal not available, aborting.' unless interactive?

        $stdin.gets.to_s.chomp
      rescue Interrupt
        ''
      end
    end

    extend ClassMethods
    include ClassMethods
  end
end
