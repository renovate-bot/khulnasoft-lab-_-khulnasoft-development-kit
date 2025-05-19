khulnasoft_zoekt_indexer_dir = ${khulnasoft_development_root}/khulnasoft-zoekt-indexer

.PHONY: khulnasoft-zoekt-setup
ifeq ($(zoekt_enabled),true)
khulnasoft-zoekt-setup: khulnasoft-zoekt-indexer/.git/pull khulnasoft-zoekt-indexer/bin/khulnasoft-zoekt
else
khulnasoft-zoekt-setup:
	@true
endif

.PHONY: khulnasoft-zoekt-update
ifeq ($(zoekt_enabled),true)
khulnasoft-zoekt-update: khulnasoft-zoekt-update-timed
else
khulnasoft-zoekt-update:
	@true
endif

.PHONY: khulnasoft-zoekt-update-run
khulnasoft-zoekt-run: khulnasoft-zoekt-indexer/.git/pull khulnasoft-zoekt-indexer-clean-bin khulnasoft-zoekt-indexer/bin/khulnasoft-zoekt-indexer

khulnasoft-zoekt-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_zoekt_indexer_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_zoekt_indexer_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_zoekt_indexer_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_zoekt_indexer_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_zoekt_indexer_dir} && $(MISE_INSTALL)
else
	@true
endif

khulnasoft-zoekt-clean-bin:
	$(Q)rm -rf khulnasoft-zoekt-indexer/bin/*

khulnasoft-zoekt-indexer/.git:
	$(Q)GIT_REVISION="${khulnasoft_zoekt_indexer_version}" support/component-git-clone ${git_params} ${khulnasoft_zoekt_indexer_repo} khulnasoft-zoekt-indexer

.PHONY: khulnasoft-zoekt-indexer/bin/khulnasoft-zoekt
khulnasoft-zoekt-indexer/bin/khulnasoft-zoekt: khulnasoft-zoekt-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building khulnasoft-org/khulnasoft-zoekt version ${khulnasoft_zoekt_indexer_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec khulnasoft-zoekt-indexer $(MAKE) build_unified ${QQ}

.PHONY: khulnasoft-zoekt-indexer/.git/pull
khulnasoft-zoekt-indexer/.git/pull: khulnasoft-zoekt-indexer/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/khulnasoft-zoekt-indexer"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update zoekt khulnasoft-zoekt-indexer "${khulnasoft_zoekt_indexer_version}" main
