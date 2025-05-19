# frozen_string_literal: true

module KDK
  module Command
    # Executes bundled psql command pointing to the Geo Tracking database with any provided extra arguments
    class PsqlGeo < BaseCommand
      def run(args = [])
        exec(*KDK::PostgresqlGeo.new.psql_cmd(args), chdir: KDK.root)
      end
    end
  end
end
