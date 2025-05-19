# frozen_string_literal: true

module KDK
  module Diagnostic
    class MacPorts < Base
      TITLE = 'MacPorts'
      MAC_PORTS_BIN = '/opt/local/bin/port'
      POSTGRESQL_COMPILATION_PROBLEM_ISSUE = 'https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/1362'
      MAC_PORTS_UNINSTALLATION_LINK = 'https://guide.macports.org/chunked/installing.macports.uninstalling.html'
      MIGRATE_TO_ASDF_LINK = 'https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/master/doc/migrate_to_asdf.md'

      def success?
        !File.exist?(MAC_PORTS_BIN)
      end

      def detail
        return if success?

        <<~MAC_PORTS_INSTALLED_MSG
          MacPorts is installed (`#{MAC_PORTS_BIN}` exists). Having MacPorts installed (especially old/outdated versions)
          can cause major issues when it comes to compiling software.

          A really common issue is trying to compile PostgreSQL (see #{POSTGRESQL_COMPILATION_PROBLEM_ISSUE}),
          so we advise to uninstall MacPorts (#{MAC_PORTS_UNINSTALLATION_LINK}) and rely on
          `asdf` instead (#{MIGRATE_TO_ASDF_LINK}).
        MAC_PORTS_INSTALLED_MSG
      end
    end
  end
end
