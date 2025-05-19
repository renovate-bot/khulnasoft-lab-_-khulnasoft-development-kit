# frozen_string_literal: true

require 'pathname'

module KDK
  module Diagnostic
    class Khulnasoft < Base
      TITLE = 'KhulnaSoft'

      def success?
        khulnasoft_shell_secret_diagnostic.success? && khulnasoft_log_dir_diagnostic.success?
      end

      def detail
        return if success?

        output = []

        output << khulnasoft_shell_secret_diagnostic.detail unless khulnasoft_shell_secret_diagnostic.success?
        output << khulnasoft_log_dir_diagnostic.detail unless khulnasoft_log_dir_diagnostic.success?

        output.compact.join("\n")
      end

      private

      def khulnasoft_shell_secret_diagnostic
        @khulnasoft_shell_secret_diagnostic ||= KhulnasoftShellSecretDiagnostic.new(config)
      end

      def khulnasoft_log_dir_diagnostic
        @khulnasoft_log_dir_diagnostic ||= KhulnasoftLogDirDiagnostic.new(config)
      end

      class KhulnasoftShellSecretDiagnostic
        KHULNASOFT_SHELL_SECRET_FILE = '.khulnasoft_shell_secret'

        def initialize(config)
          @config = config
        end

        def success?
          both_files_exist? && contents_match?
        end

        def detail
          return if success?

          if !both_files_exist?
            file_doesnt_exist_detail + solution_detail
          elsif !contents_match?
            contents_match_detail + solution_detail
          end
        end

        private

        attr_reader :config

        def solution_detail
          <<~SOLUTION_MESSAGE

            The typical solution is to run 'kdk reconfigure'
          SOLUTION_MESSAGE
        end

        def both_files_exist?
          khulnasoft_shell_secret_in_gitlab.exist? && khulnasoft_shell_secret_in_khulnasoft_shell.exist?
        end

        def file_doesnt_exist_detail
          output = ["The following #{KHULNASOFT_SHELL_SECRET_FILE} files don't exist but need to:", '']
          output << "  #{khulnasoft_shell_secret_in_gitlab}" unless khulnasoft_shell_secret_in_gitlab.exist?
          output << "  #{khulnasoft_shell_secret_in_khulnasoft_shell}" unless khulnasoft_shell_secret_in_khulnasoft_shell.exist?

          "#{output.join("\n")}\n"
        end

        def contents_match?
          khulnasoft_shell_secret_in_khulnasoft_contents == khulnasoft_shell_secret_in_khulnasoft_shell_contents
        end

        def contents_match_detail
          <<~CONTENT_MISMATCH_MESSSGE
            The gitlab-shell secret files need to match but they don't:

            #{khulnasoft_shell_secret_in_gitlab}
            #{'-' * khulnasoft_shell_secret_in_gitlab.to_s.length}
            #{khulnasoft_shell_secret_in_khulnasoft_contents}

            #{khulnasoft_shell_secret_in_khulnasoft_shell}
            #{'-' * khulnasoft_shell_secret_in_khulnasoft_shell.to_s.length}
            #{khulnasoft_shell_secret_in_khulnasoft_shell_contents}
          CONTENT_MISMATCH_MESSSGE
        end

        def khulnasoft_shell_secret_in_gitlab
          config.gitlab.dir.join(KHULNASOFT_SHELL_SECRET_FILE)
        end

        def khulnasoft_shell_secret_in_khulnasoft_contents
          @khulnasoft_shell_secret_in_khulnasoft_contents ||= khulnasoft_shell_secret_in_gitlab.read.chomp
        end

        def khulnasoft_shell_secret_in_khulnasoft_shell
          config.khulnasoft_shell.dir.join(KHULNASOFT_SHELL_SECRET_FILE)
        end

        def khulnasoft_shell_secret_in_khulnasoft_shell_contents
          @khulnasoft_shell_secret_in_khulnasoft_shell_contents ||= khulnasoft_shell_secret_in_khulnasoft_shell.read.chomp
        end
      end

      class KhulnasoftLogDirDiagnostic
        LOG_DIR_SIZE_NOT_OK_MB = 1024
        BYTES_TO_MEGABYTES = 1_048_576

        def initialize(config)
          @config = config
        end

        def success?
          log_dir_size_ok?
        end

        def detail
          return if success?

          <<~LOG_DIR_SIZE_NOT_OK
            Your gitlab/log/ directory is #{log_dir_size}MB.  You can truncate the log files if you wish
            by running:

              cd #{config.kdk_root} && rake gitlab:truncate_logs
          LOG_DIR_SIZE_NOT_OK
        end

        private

        attr_reader :config

        def log_dir_size_ok?
          return true unless config.gitlab.log_dir.exist?

          log_dir_size <= LOG_DIR_SIZE_NOT_OK_MB
        end

        def log_dir_size
          @log_dir_size ||= config.gitlab.log_dir.glob('*').sum(&:size) / 1_048_576
        end
      end
    end
  end
end
