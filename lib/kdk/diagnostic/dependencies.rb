# frozen_string_literal: true

module KDK
  module Diagnostic
    class Dependencies < Base
      TITLE = 'KDK Dependencies'

      def success?
        checker.error_messages.empty?
      end

      def detail
        return if success?

        messages = checker.error_messages.join("\n").chomp

        <<~MESSAGE
          #{messages}

          Please run:
            (cd #{config.kdk_root} && rm -fr #{cache_files(true).map(&:to_s).join(' ')} && support/bootstrap)

          For details on how to install, please visit:

          https://github.com/khulnasoft-lab/khulnasoft-development-kit/blob/master/doc/index.md
        MESSAGE
      end

      def correct!
        cache_files.each(&:rmtree)

        sh = Shellout.new('support/bootstrap')
        sh.run

        raise "Failed to run `support/bootstrap`:\n#{sh.read_stderr}" unless sh.success?
      end

      private

      def checker
        @checker ||= KDK::Dependencies::Checker.new.tap(&:check_all)
      end

      def cache_files(relative = false)
        [
          cache_file('.kdk_bootstrapped'),
          cache_file('.kdk_platform_setup')
        ].map { |p| relative ? p.relative_path_from(config.kdk_root) : p }
      end

      def cache_file(path)
        config.__cache_dir.join(path)
      end
    end
  end
end
