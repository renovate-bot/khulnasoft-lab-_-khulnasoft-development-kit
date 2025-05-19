# frozen_string_literal: true

module KDK
  module Diagnostic
    class Praefect < Base
      TITLE = 'Praefect'

      def success?
        migrations_ok?
      end

      def detail
        return if success?

        output = []
        output << migrations_not_ok_message unless migrations_ok?

        output.join("\n#{diagnostic_detail_break}\n")
      end

      private

      def praefect_bin_path
        @praefect_bin_path ||= config.gitaly.__build_bin_path.join('praefect')
      end

      def praefect_config_path
        @praefect_config_path ||= config.gitaly.dir.join('praefect.config.toml')
      end

      def migrations_check_command
        @migrations_check_command ||= "#{praefect_bin_path} -config #{praefect_config_path} sql-migrate-status"
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
          The following praefect DB migrations don't appear to have been applied:

            #{migrations_needing_attention.join("\n  ")}

          For full output you can run:

            #{migrations_check_command}

          To fix, you can run:

            kdk reset-praefect-data
        MIGRATIONS_NOT_OK_MESSAGE
      end
    end
  end
end
