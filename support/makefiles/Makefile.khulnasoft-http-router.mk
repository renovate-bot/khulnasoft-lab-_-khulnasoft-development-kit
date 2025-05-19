khulnasoft_http_router_dir = ${khulnasoft_development_root}/khulnasoft-http-router

.PHONY: khulnasoft-http-router-setup
ifeq ($(khulnasoft_http_router_enabled),true)
khulnasoft-http-router-setup: khulnasoft-http-router-setup-timed
else
khulnasoft-http-router-setup:
	@true
endif

.PHONY: khulnasoft-http-router-setup-run
khulnasoft-http-router-setup-run: khulnasoft-http-router/.git khulnasoft-http-router-common-setup

khulnasoft-http-router/.git:
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_http_router_repo} khulnasoft-http-router

.PHONY: khulnasoft-http-router-common-setup
khulnasoft-http-router-common-setup: touch-examples khulnasoft-http-router-npm-install

.PHONY: khulnasoft-http-router-npm-install
khulnasoft-http-router-npm-install: khulnasoft-http-router-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Performing npm steps for ${khulnasoft_http_router_dir}"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_http_router_dir} && npm install

.PHONY: khulnasoft-http-router-asdf-install
khulnasoft-http-router-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_http_router_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_http_router_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_http_router_dir}/.tool-versions" $(ASDF_INSTALL)
	$(Q)cd ${khulnasoft_http_router_dir} && asdf reshim
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_http_router_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_http_router_dir} && $(MISE_INSTALL)
else
	@echo "No tooling manager found for ${khulnasoft_http_router_dir}"
	@true
endif

.PHONY: khulnasoft-http-router-update
ifeq ($(khulnasoft_http_router_enabled),true)
khulnasoft-http-router-update: khulnasoft-http-router-update-timed
else
khulnasoft-http-router-update:
	@true
endif

.PHONY: ensure-khulnasoft-http-router-stopped
ensure-khulnasoft-http-router-stopped:
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring khulnasoft-http-router is stopped"
	@echo "See https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/2159"
	@echo "${DIVIDER}"
	$(Q)kdk stop khulnasoft-http-router

.PHONY: khulnasoft-http-router-update-run
khulnasoft-http-router-update-run: ensure-khulnasoft-http-router-stopped khulnasoft-http-router/.git/pull khulnasoft-http-router-common-setup
	$(Q)kdk restart khulnasoft-http-router

.PHONY: khulnasoft-http-router/.git/pull
khulnasoft-http-router/.git/pull: khulnasoft-http-router/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating ${khulnasoft_http_router_dir}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_http_router khulnasoft-http-router "${khulnasoft_http_router_version}" main
