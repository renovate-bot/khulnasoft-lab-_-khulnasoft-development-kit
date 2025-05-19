postgresql/geo: postgresql-geo/data postgresql-geo/data/khulnasoft.conf postgresql/geo/seed-data

postgresql-geo/data:
ifeq ($(geo_enabled), true)
ifeq ($(geo_secondary), true)
	$(Q)${postgresql_bin_dir}/initdb --locale=C -E utf-8 postgresql-geo/data
else
	@true
endif
endif

.PHONY: postgresql-geo/data/khulnasoft.conf
postgresql-geo/data/khulnasoft.conf:
ifeq ($(geo_enabled), true)
ifeq ($(geo_secondary), true)
	$(Q). ./support/bootstrap-common.sh ; ensure_line_in_file "include 'khulnasoft.conf'" "postgresql-geo/data/postgresql.conf"
	$(Q)rake postgresql-geo/data/khulnasoft.conf
else
	@true
endif
endif

postgresql/geo/Procfile:
	$(Q)grep '^postgresql-geo:' Procfile || (printf ',s/^#postgresql-geo/postgresql-geo/\nwq\n' | ed -s Procfile)

postgresql/geo/seed-data:
ifeq ($(geo_enabled), true)
ifeq ($(geo_secondary), true)
	$(Q)support/bootstrap-geo
else
	@true
endif
endif

postgresql-geo-replication-primary: postgresql-replication/config

postgresql-geo-replication-secondary: postgresql-geo-secondary-replication/data postgresql-replication/backup postgresql-replication/config

postgresql-geo-secondary-replication/data:
	${postgresql_bin_dir}/initdb --locale=C -E utf-8 ${postgresql_data_dir}
