khulnasoft_elasticsearch_indexer_dir =  ${khulnasoft_development_root}/gitlab-elasticsearch-indexer

ifeq ($(khulnasoft_elasticsearch_indexer_enabled),true)
gitlab-elasticsearch-indexer-setup: gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer
else
gitlab-elasticsearch-indexer-setup:
	@true
endif

.PHONY: gitlab-elasticsearch-indexer-update
ifeq ($(khulnasoft_elasticsearch_indexer_enabled),true)
gitlab-elasticsearch-indexer-update: gitlab-elasticsearch-indexer-update-timed
else
gitlab-elasticsearch-indexer-update:
	@true
endif

.PHONY: gitlab-elasticsearch-indexer-update-run
gitlab-elasticsearch-indexer-update-run: gitlab-elasticsearch-indexer/.git/pull gitlab-elasticsearch-indexer-clean-bin gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer

gitlab-elasticsearch-indexer-clean-bin:
	$(Q)rm -rf gitlab-elasticsearch-indexer/bin

gitlab-elasticsearch-indexer/.git:
	$(Q)GIT_REVISION="${khulnasoft_elasticsearch_indexer_version}" support/component-git-clone ${git_params} ${khulnasoft_elasticsearch_indexer_repo} gitlab-elasticsearch-indexer

.PHONY: gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer
gitlab-elasticsearch-indexer/bin/gitlab-elasticsearch-indexer: gitlab-elasticsearch-indexer/.git/pull gitlab-elasticsearch-indexer-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building gitlab-org/gitlab-elasticsearch-indexer version ${khulnasoft_elasticsearch_indexer_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec gitlab-elasticsearch-indexer $(MAKE) build ${QQ}

.PHONY: gitlab-elasticsearch-indexer/.git/pull
gitlab-elasticsearch-indexer/.git/pull: gitlab-elasticsearch-indexer/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-elasticsearch-indexer"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_elasticsearch_indexer gitlab-elasticsearch-indexer "${khulnasoft_elasticsearch_indexer_version}" main

gitlab-elasticsearch-indexer-asdf-install:
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
