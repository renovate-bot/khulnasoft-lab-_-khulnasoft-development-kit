# frozen_string_literal: true

module KDK
  module Command
    class Telemetry < BaseCommand
      def run(_ = [])
        print KDK::Telemetry::PROMPT_TEXT
        answer = $stdin.gets&.strip&.downcase

        case answer
        when nil
          puts 'No input received. Keeping previous behavior.'
        when 'y', 'n'
          KDK::Telemetry.update_settings(answer)
          puts tracking_message
        else
          puts 'Input not valid. Keeping previous behavior.'
        end

        true
      rescue Interrupt
        puts
        puts "Keeping previous behavior: #{tracking_message}"
        true
      end

      private

      def tracking_message
        if KDK::Telemetry.telemetry_enabled?
          'Telemetry is enabled. Data will be collected anonymously.'
        else
          'Telemetry is disabled. No data will be collected.'
        end
      end
    end
  end
end
