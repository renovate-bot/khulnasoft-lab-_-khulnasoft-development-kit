khulnasoft_topology_service_dir = ${khulnasoft_development_root}/khulnasoft-topology-service

.PHONY: khulnasoft-topology-service-setup
ifeq ($(khulnasoft_topology_service_enabled),true)
khulnasoft-topology-service-setup: khulnasoft-topology-service-setup-timed khulnasoft-topology-service/config.toml
else
khulnasoft-topology-service-setup:
	@true
endif

.PHONY: khulnasoft-topology-service-setup-run
khulnasoft-topology-service-setup-run: khulnasoft-topology-service/.git khulnasoft-topology-service-common-setup
	$(Q)kdk restart khulnasoft-topology-service

khulnasoft-topology-service/.git:
	$(Q)rm -fr khulnasoft-topology-service/config.toml
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_topology_service_repo} khulnasoft-topology-service

.PHONY: khulnasoft-topology-service-common-setup
khulnasoft-topology-service-common-setup: touch-examples khulnasoft-topology-service/config.toml khulnasoft-topology-service-make-deps-install

.PHONY: khulnasoft-topology-service-make-deps-install
khulnasoft-topology-service-make-deps-install: khulnasoft-topology-service-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Performing make deps steps for ${khulnasoft_topology_service_dir}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec ${khulnasoft_topology_service_dir} make deps

.PHONY: khulnasoft-topology-service-asdf-install
khulnasoft-topology-service-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_topology_service_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q). support/bootstrap-common.sh; cd ${khulnasoft_topology_service_dir}; asdf_install_update_plugins
	$(Q)cd ${khulnasoft_topology_service_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_topology_service_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_topology_service_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_topology_service_dir} && $(MISE_INSTALL)
else
	@true
endif

.PHONY: khulnasoft-topology-service-update
ifeq ($(khulnasoft_topology_service_enabled),true)
khulnasoft-topology-service-update: khulnasoft-topology-service-update-timed
else
khulnasoft-topology-service-update:
	@true
endif

.PHONY: khulnasoft-topology-service-update-run
khulnasoft-topology-service-update-run: khulnasoft-topology-service/.git/pull khulnasoft-topology-service-common-setup khulnasoft-topology-service/config.toml
	$(Q)kdk restart khulnasoft-topology-service

.PHONY: khulnasoft-topology-service/.git/pull
khulnasoft-topology-service/.git/pull: khulnasoft-topology-service/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating ${khulnasoft_topology_service_dir}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_topology_service khulnasoft-topology-service "${khulnasoft_topology_service_version}" main
