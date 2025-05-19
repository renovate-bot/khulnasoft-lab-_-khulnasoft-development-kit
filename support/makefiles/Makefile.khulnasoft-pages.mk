khulnasoft_pages_dir = ${khulnasoft_development_root}/gitlab-pages

ifeq ($(khulnasoft_pages_enabled),true)
gitlab-pages-setup: gitlab-pages-update-timed
else
gitlab-pages-setup:
	@true
endif

ifeq ($(khulnasoft_pages_enabled),true)
gitlab-pages-update: gitlab-pages-update-timed
else
gitlab-pages-update:
	@true
endif

.PHONY: gitlab-pages-update-run
gitlab-pages-update-run: gitlab-pages-secret gitlab-pages/gitlab-pages.conf gitlab-pages/bin/gitlab-pages

gitlab-pages-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_pages_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_pages_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_pages_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_pages_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_pages_dir} && $(MISE_INSTALL)
else
	@true
endif

.PHONY: gitlab-pages/bin/gitlab-pages
gitlab-pages/bin/gitlab-pages: gitlab-pages/.git/pull gitlab-pages-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling gitlab-org/gitlab-pages"
	@echo "${DIVIDER}"
	$(Q)rm -f gitlab-pages/bin/gitlab-pages
	$(Q)support/asdf-exec ${khulnasoft_pages_dir} $(MAKE) ${QQ}

gitlab-pages/.git:
	$(Q)GIT_REVISION="${khulnasoft_pages_version}" support/component-git-clone ${git_params} ${khulnasoft_pages_repo} ${khulnasoft_pages_dir} ${QQ}

gitlab-pages/.git/pull: gitlab-pages/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-pages to ${khulnasoft_pages_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_pages "${khulnasoft_pages_dir}" "${khulnasoft_pages_version}" master
