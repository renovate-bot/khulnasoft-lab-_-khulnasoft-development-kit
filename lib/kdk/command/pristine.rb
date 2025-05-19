# frozen_string_literal: true

require 'fileutils'

module KDK
  module Command
    # Handles `kdk pristine` command execution
    class Pristine < BaseCommand
      BUNDLE_PRISTINE_CMD = 'bundle pristine'
      YARN_CLEAN_CMD = 'yarn clean'
      GIT_CLEAN_TMP_CMD = 'git clean -fX -- tmp/'
      RESET_CONFIGS_CMD = 'make reconfigure'

      def run(_args = [])
        %i[
          kdk_stop
          kdk_tmp_clean
          kdk_bundle
          reset_configs
          khulnasoft_bundle
          khulnasoft_tmp_clean
          khulnasoft_yarn_clean
        ].each do |task_name|
          run_task(task_name)
        end

        KDK::Output.success("Successfully ran 'kdk pristine'!")

        true
      rescue StandardError => e
        KDK::Output.error("Failed to run 'kdk pristine' - #{e.message}.", e)
        display_help_message

        false
      end

      def bundle_install_cmd
        "bundle install --jobs #{KDK.config.restrict_cpu_count} --quiet"
      end

      private

      def run_task(method_name)
        send(method_name) || # rubocop:disable KhulnasoftSecurity/PublicSend
          raise("Had an issue with '#{method_name}'")
      end

      def notice(msg)
        KDK::Output.notice(msg)
      end

      def kdk_stop
        notice('Stopping KDK..')
        Runit.stop(quiet: true)
      end

      def kdk_tmp_clean
        notice('Cleaning KDK tmp/ ..')
        shellout(GIT_CLEAN_TMP_CMD)
      end

      def kdk_bundle
        notice('Ensuring KDK Ruby gems are installed and pristine..')
        kdk_bundle_install && kdk_bundle_pristine
      end

      def reset_configs
        shellout(RESET_CONFIGS_CMD)
      end

      def kdk_bundle_install
        shellout(bundle_install_cmd)
      end

      def kdk_bundle_pristine
        shellout(BUNDLE_PRISTINE_CMD)
      end

      def khulnasoft_bundle
        notice('Ensuring gitlab/ Ruby gems are installed and pristine..')
        khulnasoft_bundle_install && khulnasoft_bundle_pristine
      end

      def khulnasoft_bundle_install
        shellout(bundle_install_cmd, chdir: config.gitlab.dir)
      end

      def khulnasoft_bundle_pristine
        shellout(BUNDLE_PRISTINE_CMD, chdir: config.gitlab.dir)
      end

      def khulnasoft_yarn_clean
        notice('Cleaning gitlab/ Yarn cache..')
        shellout(YARN_CLEAN_CMD, chdir: config.gitlab.dir)
      end

      def khulnasoft_tmp_clean
        notice('Cleaning gitlab/tmp/ ..')
        shellout(GIT_CLEAN_TMP_CMD, chdir: config.gitlab.dir)
      end

      def shellout(cmd, **opts)
        sh = Shellout.new(cmd, **opts)
        sh.stream
        sh.success?
      rescue StandardError => e
        KDK::Output.puts(e.message, stderr: true)
        false
      end
    end
  end
end
