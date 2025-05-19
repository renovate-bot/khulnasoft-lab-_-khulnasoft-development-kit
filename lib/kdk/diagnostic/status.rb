# frozen_string_literal: true

module KDK
  module Diagnostic
    class Status < Base
      TITLE = 'KDK Status'
      RED_TRIANGLE_DOWN_ICON = "\u{1f53b}"

      def success?
        down_services.empty?
      end

      def detail
        return if success?

        lines = ['The following services are not running but should be:']

        down_services.each do |service|
          service_name = service.split('/').last.split(':').first
          log_details = fetch_service_log(service_name)
          last_error = extract_error_message(log_details)

          lines << (" #{RED_TRIANGLE_DOWN_ICON} #{service_name} → #{last_error}")
        end

        lines.join("\n")
      end

      private

      def kdk_status_command
        @kdk_status_command ||= Shellout.new('kdk status').execute(display_output: false, display_error: false)
      end

      def down_services
        @down_services ||= kdk_status_command.read_stdout.split("\n").grep(/\Adown: .+, want up;.+\z/)
      end

      def fetch_service_log(service_name)
        log_path = Pathname.new(KDK.root).join('log', service_name.to_s, 'current')
        return "Log file not found for #{service_name}" unless log_path.exist?

        File.open(log_path, 'r') do |file|
          file.each_line.reverse_each.find { |line| !line.strip.empty? }&.strip
        end
      end

      def extract_error_message(log_content)
        error_patterns = {
          /bind.*can't assign requested address/i => "The service couldn't use the required address. This could be due to another application using it or the network is not set up correctly."
        }

        error_patterns.each do |pattern, message|
          return message if log_content.match?(pattern)
        end

        log_content
      end
    end
  end
end
