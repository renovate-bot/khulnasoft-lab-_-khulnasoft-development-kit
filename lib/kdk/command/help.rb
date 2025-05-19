# frozen_string_literal: true

require 'fileutils'

module KDK
  module Command
    class Help < BaseCommand
      # Allow invalid kdk.yml.
      def self.validate_config?
        false
      end

      def run(_ = [])
        KDK::Logo.print
        KDK::Output.puts(File.read(KDK.root.join('HELP')))

        true
      end
    end
  end
end
