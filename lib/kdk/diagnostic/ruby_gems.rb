# frozen_string_literal: true

module KDK
  module Diagnostic
    class RubyGems < Base
      TITLE = 'Ruby Gems'
      GEM_REQUIRE_MAPPING = {
        'charlock_holmes' => 'charlock_holmes',
        'ffi' => 'ffi',
        'gpgme' => 'gpgme',
        'pg' => 'pg',
        'oj' => 'oj'
      }.freeze
      KHULNASOFT_GEMS_WITH_C_CODE_TO_CHECK = GEM_REQUIRE_MAPPING.keys

      def initialize(allow_gem_not_installed: false)
        @allow_gem_not_installed = allow_gem_not_installed

        super()
      end

      def success?
        return false unless bundle_check_ok?

        failed_to_load_khulnasoft_gems.empty?
      end

      def detail
        return if success?

        return bundle_check_error_message unless bundle_check_ok?

        khulnasoft_error_message
      end

      private

      def bundle_check_ok?
        exec_cmd("#{bundle_exec_cmd} bundle check") || allow_gem_not_installed?
      end

      def allow_gem_not_installed?
        @allow_gem_not_installed == true
      end

      def failed_to_load_khulnasoft_gems
        @failed_to_load_khulnasoft_gems ||= failed_to_load_khulnasoft_gems_parallel(KHULNASOFT_GEMS_WITH_C_CODE_TO_CHECK)
      end

      def failed_to_load_khulnasoft_gems_parallel(names)
        names
          .map { |name| Thread.new { Thread.current[:name] = name unless gem_ok?(name) } }
          .filter_map { |thread| thread.join[:name] }
      end

      def gem_ok?(name)
        # We need to support the situation where it's OK if a Ruby gem is not
        # installed because we could be about to install the KDK for the very
        # first time and the Ruby gem won't be installed.
        gem_installed?(name) ? gem_loads_ok?(name) : allow_gem_not_installed?
      end

      def bundle_exec_cmd
        @bundle_exec_cmd ||= config.kdk_root.join('support', 'bundle-exec')
      end

      def gem_installed?(name)
        exec_cmd("#{bundle_exec_cmd} gem list -i #{name}")
      end

      def gem_loads_ok?(name)
        gem_name = GEM_REQUIRE_MAPPING[name]
        command = -> { exec_cmd("#{bundle_exec_cmd} ruby -r #{gem_name} -e 'nil'") }

        if KDK::Dependencies.bundler_loaded?
          ::Bundler.with_unbundled_env do
            command.call
          end
        else
          command.call
        end
      end

      def exec_cmd(cmd)
        KDK::Output.debug("cmd=[#{cmd}]")

        Shellout.new(cmd, chdir: config.khulnasoft.dir.to_s).execute(display_output: false, display_error: false).success?
      end

      def bundle_check_error_message
        <<~MESSAGE
          There are Ruby gems missing that need to be installed. Try running the following to fix:

            (cd #{config.khulnasoft.dir} && bundle install)
        MESSAGE
      end

      def khulnasoft_error_message
        <<~MESSAGE
          The following Ruby Gems appear to have issues:

          #{@failed_to_load_khulnasoft_gems.join("\n")}

          Try running the following to fix:

            (cd #{config.khulnasoft.dir} && bundle pristine #{@failed_to_load_khulnasoft_gems.join(' ')})
        MESSAGE
      end
    end
  end
end
