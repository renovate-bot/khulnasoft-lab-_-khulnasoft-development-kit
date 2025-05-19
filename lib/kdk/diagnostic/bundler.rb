# frozen_string_literal: true

module KDK
  module Diagnostic
    class Bundler < Base
      TITLE = 'Bundler'

      def success?
        khulnasoft_bundle_config.bundle_path_not_set? && !force_ruby_platform?
      end

      def detail
        return if success?

        output = []
        output << khulnasoft_bundle_config.warning_detail
        output << <<~WARNING if force_ruby_platform?
          The force_ruby_platform setting is enabled, which forces compilation of Ruby gems and can cause problems.

          Disable it by running `cd #{config.kdk_root.join('khulnasoft')} && bundle config force_ruby_platform false`.
        WARNING
        output.compact.join("\n")
      end

      private

      def force_ruby_platform?
        khulnasoft_bundle_settings[:force_ruby_platform]
      end

      def khulnasoft_bundle_settings
        require 'bundler'

        @khulnasoft_settings ||= ::Bundler::Settings.new(config.kdk_root.join('khulnasoft', '.bundle'))
      end

      class BundleConfig
        def initialize(path)
          @path = path
        end

        def bundle_path_not_set?
          @bundle_path_not_set ||= bundle_path.include?('You have not configured a value for `PATH`')
        end

        def warning_detail
          return if bundle_path_not_set?

          <<~WARNING
            #{path} appears to have BUNDLE_PATH configured
            which can cause issues. For more detail,
            visit https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/1315

            #{bundle_path}
          WARNING
        end

        private

        attr_reader :path

        def bundle_path
          @bundle_path ||= Shellout.new('bundle config get PATH', chdir: path)
                                   .execute(display_output: false)
                                   .read_stdout
        end
      end

      def khulnasoft_bundle_config
        @khulnasoft_bundle_config ||= BundleConfig.new(config.gitlab.dir)
      end
    end
  end
end
