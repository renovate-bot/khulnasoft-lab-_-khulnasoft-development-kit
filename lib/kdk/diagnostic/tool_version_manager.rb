# frozen_string_literal: true

require 'json'

module KDK
  module Diagnostic
    # Notifies users about the supported tool version manager and suggests migrating from asdf to mise.
    class ToolVersionManager < Base
      TITLE = 'Tool Version Manager'
      BROKEN_ASDF_VERSION_REGEX = /v0\.16\.\d+/

      def correctable?
        using_asdf? || (mise_update_command && mise_update_required?)
      end

      def correct!
        migrate_to_mise! if using_asdf?
        update_mise! if mise_update_command && mise_update_required?
      end

      def success?
        !using_asdf? && !mise_update_required?
      end

      def detail(context = nil)
        return if success?

        messages = []

        messages << <<~MESSAGE if broken_asdf_version?
          ERROR: Your installed version of asdf (`#{current_asdf_version}`) has a bug that makes it incompatible with KDK.
          Please downgrade to `v0.15.0` or switch to `mise`.
        MESSAGE

        if using_asdf?
          messages << <<~MESSAGE
            We're dropping support for asdf in KDK.

            You can still use asdf if you need to, for example outside of KDK. But it's no longer supported in KDK and won't be maintained going forward.

            Mise provides better supply chain security while running faster and avoiding the dependency installation problems that we had to manually fix with asdf.
          MESSAGE

          unless context == :update
            messages << <<~MESSAGE
              To migrate, run:
                kdk update
            MESSAGE
          end

          return messages.join("\n")
        end

        if mise_update_required?
          messages << <<~MESSAGE
            WARNING: Your installed version of mise (#{current_mise_version}) is out of date.
            The latest available version is #{mise_latest_version}.
          MESSAGE

          if mise_update_command
            messages << <<~MESSAGE
              To update to the latest version, run:
                `#{mise_update_command}`
            MESSAGE
          end
        end

        messages.join("\n")
      end

      private

      def using_mise?
        KDK.config.asdf.opt_out? && KDK.config.mise.enabled?
      end

      def using_asdf?
        !KDK.config.asdf.opt_out?
      end

      def broken_asdf_version?
        return false unless using_asdf?

        BROKEN_ASDF_VERSION_REGEX.match?(current_asdf_version)
      end

      def current_asdf_version
        @current_asdf_version ||= begin
          KDK::Shellout.new('asdf version').readlines.first&.strip
        rescue Errno::ENOENT
          nil
        end
      end

      def mise_version_output
        @mise_version_output ||= begin
          output = KDK::Shellout.new('mise version --json').execute(display_output: false).read_stdout
          JSON.parse(output)
        rescue Errno::ENOENT, JSON::ParserError
          {}
        end
      end

      def current_mise_version
        mise_version_output['version']&.split&.first
      end

      def mise_latest_version
        mise_version_output['latest']
      end

      def mise_update_command
        if KDK::Machine.macos?
          'brew update && brew upgrade mise'
        elsif KDK::Machine.linux?
          'apt update && apt upgrade mise'
        end
      end

      def mise_update_required?
        return false unless using_mise?

        return false unless current_mise_version && mise_latest_version

        begin
          current_version = Gem::Version.new(current_mise_version)
          latest_version = Gem::Version.new(mise_latest_version)

          current_version < latest_version
        rescue ArgumentError
          false
        end
      end

      def update_mise!
        KDK::Shellout.new(mise_update_command).execute(display_output: false)
        true
      rescue StandardError => e
        KDK::Output.warn("Failed to update mise: #{e.message}")
        false
      end

      def migrate_to_mise!
        KDK::Execute::Rake.new('mise:migrate').execute_in_kdk
      end
    end
  end
end
