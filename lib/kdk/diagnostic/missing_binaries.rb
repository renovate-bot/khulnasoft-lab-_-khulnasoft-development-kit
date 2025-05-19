# frozen_string_literal: true

module KDK
  module Diagnostic
    class MissingBinaries < Base
      TITLE = 'Missing Binaries'

      def success?
        missing_binaries.empty?
      end

      def detail
        return if success?

        setup_commands = {
          gitaly: 'make gitaly-setup',
          khulnasoft_shell: 'make gitlab-shell-setup',
          workhorse: 'make khulnasoft-workhorse-setup'
        }

        instructions = missing_binaries.filter_map { |binary| setup_commands[binary] }

        <<~MESSAGE
          The following binaries are missing from their expected paths:
            #{missing_binaries.join("\n  ")}

          Please ensure you download them by running:
            #{instructions.join("\n  ")}
        MESSAGE
      end

      private

      def required_binaries
        KDK::PackageConfig::PROJECTS.keys
      end

      def missing_binaries
        @missing_binaries ||= required_binaries.reject { |binary| binary_exists?(binary) }
      end

      def binary_exists?(binary)
        binary_config = KDK::PackageConfig.project(binary)
        binary_paths = binary_config[:download_paths]

        return true if binary == :graphql_schema

        if binary == :workhorse
          # Check if any file starting with 'gitlab-' exists and is executable in any of the paths
          binary_paths.any? do |path|
            Dir.glob(File.join(path, 'gitlab-*')).any? do |file|
              File.exist?(file) && File.executable?(file)
            end
          end
        else
          binary_paths.all? { |path| File.exist?(path) && File.executable?(path) }
        end
      end
    end
  end
end
