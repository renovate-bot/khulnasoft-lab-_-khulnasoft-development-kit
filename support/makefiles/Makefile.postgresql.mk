.PHONY: postgresql
postgresql: postgresql/data postgresql/data/gitlab.conf _postgresql-seed-dbs

postgresql/data:
	$(Q)${postgresql_bin_dir}/initdb --locale=C -E utf-8 ${postgresql_data_dir}

.PHONY: postgresql/data/gitlab.conf
postgresql/data/gitlab.conf:
	$(Q). ./support/bootstrap-common.sh ; ensure_line_in_file "include 'gitlab.conf'" "postgresql/data/postgresql.conf"
	$(Q)rake postgresql/data/gitlab.conf

.PHONY: _postgresql-seed-dbs
_postgresql-seed-dbs: _postgresql-seed-dbs-heading _postgresql-seed-praefect _postgresql-seed-rails _postgresql-init-registry

.PHONY: _postgresql-seed-dbs-heading
_postgresql-seed-dbs-heading:
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring necessary databases are setup and seeded"
	@echo "${DIVIDER}"

.PHONY: _postgresql-environment
_postgresql-environment: Procfile postgresql/data postgresql-geo/data postgresql-geo/data/gitlab.conf
	$(Q)kdk start db --quiet

.PHONY: _postgresql-seed-rails
_postgresql-seed-rails: _postgresql-environment
	$(Q)support/bootstrap-rails

.PHONY: _postgresql-seed-praefect
_postgresql-seed-praefect: _postgresql-environment
ifeq ($(praefect_enabled), true)
	$(Q)support/bootstrap-praefect
else
	@true
endif

.PHONY: _postgresql-init-registry
_postgresql-init-registry: _postgresql-environment
ifeq ($(registry_database_enabled), true)
	$(Q)support/bootstrap-registry-db
else
	@true
endif
