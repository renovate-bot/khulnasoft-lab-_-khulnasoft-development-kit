# frozen_string_literal: true

module KDK
  module Diagnostic
    class Asdf < Base
      TITLE = 'asdf'

      def success?
        return true if KDK.config.asdf.opt_out?

        no_unnecessary_software_to_uninstall?
      end

      def detail
        return if success?

        output = []
        output << display_unncessary_software_to_uninstall unless no_unnecessary_software_to_uninstall?
        output.compact.join("\n")
      end

      private

      def asdf_tool_versions
        @asdf_tool_versions ||= ::Asdf::ToolVersions.new
      end

      def no_unnecessary_software_to_uninstall?
        @no_unnecessary_software_to_uninstall ||= !asdf_tool_versions.unnecessary_software_to_uninstall?
      end

      def display_unncessary_software_to_uninstall
        output = ["You have the following software installed using asdf but KDK doesn't need them:\n"]

        asdf_tool_versions.unnecessary_installed_versions_of_software.each do |name, versions|
          output << "#{name} #{versions.keys.join(', ')}"
        end

        output << ["\nIf you know other projects don't need them and want to uninstall them, run:\n\n  cd #{config.kdk_root} && rake asdf:uninstall_unnecessary_software"]
        output
      end
    end
  end
end
