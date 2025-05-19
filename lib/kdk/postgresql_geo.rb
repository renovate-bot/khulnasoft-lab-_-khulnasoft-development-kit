# frozen_string_literal: true

module KDK
  class PostgresqlGeo < Postgresql
    private

    def postgresql_config
      @postgresql_config ||= config.postgresql.geo
    end

    def default_database
      'khulnasofthq_geo_development'
    end
  end
end
