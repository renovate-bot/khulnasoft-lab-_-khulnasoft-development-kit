# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk config` command execution
    #
    # This command accepts the following subcommands:
    # - list
    # - get <config key>
    # - set <config key> <value>
    class Config < BaseCommand
      # We need to handle conflicting configuration (Vite vs. webpack).
      # Config is validated before saving.
      def self.validate_config?
        false
      end

      def run(args = [])
        case args.shift
        when 'get'
          config_get(*args)
        when 'set'
          KDK::Output.abort('Usage: kdk config set <name> <value>', report_error: false) if args.length != 2

          config_set(*args)
        when 'list'
          KDK::Output.puts(config)
          true
        else
          KDK::Output.warn('Usage: kdk config [<get>|set] <name> [<value>]')
          KDK::Output.warn('       kdk config list')
          abort
        end
      end

      private

      def config_get(*name)
        KDK::Output.abort('Usage: kdk config get <name>', report_error: false) if name.empty?

        KDK::Output.puts(config.dig(*name))

        true
      rescue KDK::ConfigSettings::SettingUndefined
        KDK::Output.abort("Cannot get config for #{name.join('.')}", report_error: false)
      rescue KDK::ConfigSettings::UnsupportedConfiguration, KDK::ConfigType::SettingsArray::ArrayAccessError => e
        KDK::Output.abort("#{e.message}.", e, report_error: false)
      end

      def config_set(slug, value)
        value_stored_in_kdk_yml = config.user_defined?(*slug)
        old_value = config.dig(*slug)
        new_value = config.bury!(slug, value)

        Command.validate_config!

        if old_value == new_value && value_stored_in_kdk_yml
          KDK::Output.warn("'#{slug}' is already set to '#{old_value}'")
          return true
        elsif old_value == new_value && !value_stored_in_kdk_yml
          KDK::Output.success("'#{slug}' is now set to '#{new_value}' (explicitly setting '#{old_value}').")
        elsif old_value != new_value && value_stored_in_kdk_yml
          KDK::Output.success("'#{slug}' is now set to '#{new_value}' (previously '#{old_value}').")
        else
          KDK::Output.success("'#{slug}' is now set to '#{new_value}' (previously using default '#{old_value}').")
        end

        config.save_yaml!
        KDK::Output.info("Don't forget to run 'kdk reconfigure'.")

        true
      rescue KDK::ConfigSettings::SettingUndefined => e
        KDK::Output.abort("Cannot get config for '#{slug}'.", e, report_error: false)
      rescue TypeError => e
        KDK::Output.abort(e.message, e, report_error: false)
      rescue StandardError => e
        KDK::Output.error(e.message, e)
        abort
      end
    end
  end
end
