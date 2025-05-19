# frozen_string_literal: true

module KDK
  module Diagnostic
    class Geo < Base
      TITLE = 'Geo'

      def success?
        @success ||= if geo_enabled?
                       geo_secondary? ? geo_database_exists? : !geo_database_exists?
                     else
                       !geo_database_exists?
                     end
      end

      def detail
        return if success?

        <<~MESSAGE
          There is a mismatch in your Geo configuration.

          #{geo_mismatch_description}
          Please run `kdk reconfigure` to apply settings in kdk.yml.
          For more details, please refer to #{geo_howto_url}.
        MESSAGE
      end

      private

      def geo_enabled?
        config.geo.enabled
      end

      def geo_secondary?
        config.geo.secondary
      end

      def database_yml_file
        @database_yml_file ||= config.gitlab.dir.join('config', 'database.yml').expand_path.to_s
      end

      def database_yml_file_exists?
        File.exist?(database_yml_file)
      end

      def database_yml_file_content
        return {} unless database_yml_file_exists?

        raw_yaml = File.read(database_yml_file)
        YAML.safe_load(raw_yaml, aliases: true, symbolize_names: true) || {}
      end

      def database_names
        database_yml_file_content[:development].to_h.keys
      end

      def geo_database_exists?
        database_names.include?(:geo)
      end

      def geo_howto_url
        'https://github.com/khulnasoft-lab/khulnasoft-development-kit/blob/main/doc/howto/geo.md'
      end

      def geo_mismatch_description
        if !geo_enabled? && geo_database_exists?
          <<~MESSAGE
            Geo is disabled in KDK, but `#{database_yml_file}` contains geo database.
          MESSAGE
        elsif geo_enabled? && !geo_secondary? && geo_database_exists?
          <<~MESSAGE
            Geo is enabled in KDK, but not as a secondary node, so `#{database_yml_file}` should not contain geo database.
          MESSAGE
        elsif geo_enabled? && geo_secondary? && !geo_database_exists?
          <<~MESSAGE
            Geo is enabled in KDK as a secondary, but `#{database_yml_file}` does not contain geo database.
          MESSAGE
        end
      end
    end
  end
end
