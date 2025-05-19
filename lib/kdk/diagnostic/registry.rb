# frozen_string_literal: true

module KDK
  module Diagnostic
    class Registry < Base
      TITLE = 'Registry'

      def success?
        return true unless KDK.config.registry.enabled?

        migrations_ok?
      end

      def detail
        return if success?

        output = []
        output << migrations_not_ok_message unless migrations_ok?

        output.join("\n#{diagnostic_detail_break}\n")
      end

      private

      def registry_bin_path
        @registry_bin_path ||= config.registry.__registry_build_bin_path
      end

      def registry_config_path
        @registry_config_path ||= config.kdk_root.join('registry/config.yml')
      end

      def migrations_check_command
        @migrations_check_command ||= "#{registry_bin_path} database migrate status #{registry_config_path}"
      end

      def migrations_needing_attention
        @migrations_needing_attention ||= Shellout.new(migrations_check_command).readlines.each_with_object([]) do |e, a|
          m = e.match(/\A\|\s(?<migration>[^\s]+)\s+\| (?:no|unknown migration)\s+\|\z/)
          next unless m

          a << m[:migration]
        end
      end

      def migrations_ok?
        migrations_needing_attention.empty?
      end

      def migrations_not_ok_message
        <<~MIGRATIONS_NOT_OK_MESSAGE
          The following registry DB migrations don't appear to have been applied:

            #{migrations_needing_attention.join("\n  ")}

          For full output you can run:

            #{migrations_check_command}

          To fix, you can run:

            kdk reset-registry-data
        MIGRATIONS_NOT_OK_MESSAGE
      end
    end
  end
end
