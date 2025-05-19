# frozen_string_literal: true

module KDK
  module Command
    # Base interface for KDK commands
    class BaseCommand
      # Services order in which ready messages are printed.
      # Messages for missing services are printed alphabetically.
      READY_MESSAGE_ORDER = [
        KDK::Services::RailsWeb # Rails goes on top
      ].freeze

      # Ensure that kdk.yml is valid by default.
      def self.validate_config?
        true
      end

      def initialize(out: Output)
        @out = out
      end

      def run(args = [])
        raise NotImplementedError
      end

      def run_rake(name, *args)
        Rake::Task[name].invoke(*args)
        true
      rescue RuntimeError => e
        out.error(e.message, e)
        false
      end

      def help
        raise NotImplementedError
      end

      protected

      def config
        KDK.config
      end

      def print_help(args)
        return false unless args.intersect?(['-h', '--help'])

        out.puts(help)

        true
      end

      def display_help_message
        out.divider(length: 55)
        out.puts <<~HELP_MESSAGE
          You can try the following that may be of assistance:

          - Run 'kdk doctor'.

          - Visit the troubleshooting documentation:
            https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/master/doc/troubleshooting/index.md.
          - Visit https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues to
            see if there are known issues.

          - Run 'kdk reset-data' if appropriate.
          - Run 'kdk pristine' to reinstall dependencies, remove temporary files, and clear caches.
        HELP_MESSAGE
        out.divider(length: 55)
      end

      def print_ready_message
        notices = ready_messages
        return if notices.empty?

        out.puts
        notices.each { |msg| out.notice(msg) }
      end

      def ready_messages
        enabled_services
          .filter_map(&:ready_message)
          .flat_map { |message| message.split("\n") }
          .then { |notices| notices + registry_notice }
          .then { |notices| notices + outdated_notice }
          .compact
      end

      private

      attr_reader :out

      def enabled_services
        KDK::Services
          .enabled
          .sort_by { |service| READY_MESSAGE_ORDER.index(service.class) || READY_MESSAGE_ORDER.size }
      end

      def registry_notice
        return [] unless config.registry?

        ["A container registry is available at #{config.registry.__listen}."]
      end

      def outdated_notice
        [KDK::Diagnostic::Version.new.detail&.split("\n")].flatten
      end
    end
  end
end
