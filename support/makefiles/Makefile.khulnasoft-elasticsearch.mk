khulnasoft_elasticsearch_indexer_dir =  ${khulnasoft_development_root}/khulnasoft-elasticsearch-indexer

ifeq ($(khulnasoft_elasticsearch_indexer_enabled),true)
khulnasoft-elasticsearch-indexer-setup: khulnasoft-elasticsearch-indexer/bin/khulnasoft-elasticsearch-indexer
else
khulnasoft-elasticsearch-indexer-setup:
	@true
endif

.PHONY: khulnasoft-elasticsearch-indexer-update
ifeq ($(khulnasoft_elasticsearch_indexer_enabled),true)
khulnasoft-elasticsearch-indexer-update: khulnasoft-elasticsearch-indexer-update-timed
else
khulnasoft-elasticsearch-indexer-update:
	@true
endif

.PHONY: khulnasoft-elasticsearch-indexer-update-run
khulnasoft-elasticsearch-indexer-update-run: khulnasoft-elasticsearch-indexer/.git/pull khulnasoft-elasticsearch-indexer-clean-bin khulnasoft-elasticsearch-indexer/bin/khulnasoft-elasticsearch-indexer

khulnasoft-elasticsearch-indexer-clean-bin:
	$(Q)rm -rf khulnasoft-elasticsearch-indexer/bin

khulnasoft-elasticsearch-indexer/.git:
	$(Q)GIT_REVISION="${khulnasoft_elasticsearch_indexer_version}" support/component-git-clone ${git_params} ${khulnasoft_elasticsearch_indexer_repo} khulnasoft-elasticsearch-indexer

.PHONY: khulnasoft-elasticsearch-indexer/bin/khulnasoft-elasticsearch-indexer
khulnasoft-elasticsearch-indexer/bin/khulnasoft-elasticsearch-indexer: khulnasoft-elasticsearch-indexer/.git/pull khulnasoft-elasticsearch-indexer-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building khulnasoft-org/khulnasoft-elasticsearch-indexer version ${khulnasoft_elasticsearch_indexer_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec khulnasoft-elasticsearch-indexer $(MAKE) build ${QQ}

.PHONY: khulnasoft-elasticsearch-indexer/.git/pull
khulnasoft-elasticsearch-indexer/.git/pull: khulnasoft-elasticsearch-indexer/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/khulnasoft-elasticsearch-indexer"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_elasticsearch_indexer khulnasoft-elasticsearch-indexer "${khulnasoft_elasticsearch_indexer_version}" main

khulnasoft-elasticsearch-indexer-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_elasticsearch_indexer_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_elasticsearch_indexer_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_elasticsearch_indexer_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_elasticsearch_indexer_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_elasticsearch_indexer_dir} && $(MISE_INSTALL)
else
	@true
endif
