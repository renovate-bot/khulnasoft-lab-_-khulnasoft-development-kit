PG_CONFIG_FLAGS_FILE := tmp/.pg_flags

# Define a function to generate the pg_config flags
define generate_pg_flags_file
    $(shell pg_config > $(PG_CONFIG_FLAGS_FILE))
    FORCE_CLEAN=1
endef

.PHONY: pgvector-setup
ifeq ($(pgvector_enabled),true)
# Check if the flags file is outdated, and generate it if necessary
ifeq ($(wildcard $(PG_CONFIG_FLAGS_FILE)),)
    $(eval $(call generate_pg_flags_file))
else ifneq ($(shell cat $(PG_CONFIG_FLAGS_FILE)), $(shell pg_config))
    $(eval $(call generate_pg_flags_file))
endif

PGVECTOR_INSTALLED_LIB := $(shell pg_config --libdir)/vector.so

pgvector-setup: pgvector-auto-clean pgvector-installed-lib
else
pgvector-setup:
	@true
endif

.PHONY: pgvector-update
ifeq ($(pgvector_enabled),true)
pgvector-update: pgvector-update-timed
else
pgvector-update:
	@true
endif

.PHONY: pgvector-update-run
pgvector-update-run: pgvector/.git/pull pgvector-clean pgvector-installed-lib pgvector-update-extension

pgvector/.git:
	$(Q)GIT_REVISION="${pgvector_version}" CLONE_DIR=pgvector support/component-git-clone ${git_params} ${pgvector_repo} pgvector

.PHONY: pgvector-auto-clean
pgvector-auto-clean: $(PG_CONFIG_FLAGS_FILE)
	$(if $(and $(FORCE_CLEAN), $(wildcard pgvector)), \
		@echo "Cleaning pgvector build since pg_config flags have changed" && support/asdf-exec pgvector $(MAKE) clean ${QQ})

.PHONY: pgvector-installed-lib
pgvector-installed-lib: $(PGVECTOR_INSTALLED_LIB)

$(PGVECTOR_INSTALLED_LIB): pgvector/vector.so
	@echo
	@echo "${DIVIDER}"
	@echo "Installing pgvector ${pgvector_version} in $@"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec pgvector $(MAKE) install ${QQ}

.PHONY: pgvector-update-extension
pgvector-update-extension:
ifeq ($(embedding), true)
	$(Q)kdk psql -c "ALTER EXTENSION vector UPDATE" -d "embedding";
endif

pgvector/vector.so: pgvector/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Building $@ version ${pgvector_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec pgvector $(MAKE) ${QQ}
	$(Q)support/asdf-exec pgvector $(MAKE) install ${QQ}

.PHONY: pgvector-clean
pgvector-clean:
	$(Q)support/asdf-exec pgvector $(MAKE) clean ${QQ}

.PHONY: pgvector/.git/pull
pgvector/.git/pull: pgvector/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/pgvector"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update pgvector pgvector "${pgvector_version}" main
