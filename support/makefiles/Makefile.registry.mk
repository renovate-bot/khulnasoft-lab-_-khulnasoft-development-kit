registry_dir = ${khulnasoft_development_root}/container-registry

ifeq ($(registry_enabled),true)
registry-setup: registry/bin/registry registry/storage registry/config.yml localhost.crt registry-migrate
else
registry-setup:
	@true
endif

.PHONY: registry-update
registry-update:
ifeq ($(registry_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Setting up container-registry ${registry_version}"
	@echo "${DIVIDER}"
	$(Q)$(MAKE) registry-update-timed
else
	@true
endif

.PHONY: registry-update-run
registry-update-run: registry/.git/pull registry-clean-bin registry/bin/registry registry-migrate

registry-clean-bin:
	$(Q)rm -rf container-registry/bin

registry/.git:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating registry"
	@echo "${DIVIDER}"
	$(Q)if [ -e container-registry ]; then mv container-registry .backups/$(shell date +container-registry.old.%Y-%m-%d_%H.%M.%S); fi
	$(Q)support/component-git-clone ${git_params} ${registry_repo} ${registry_dir}
	$(Q)support/component-git-update registry "${registry_dir}" "${registry_version}" master

registry/bin/registry: registry/.git/pull registry-asdf-install
	@echo
	@echo "${DIVIDER}"
	@echo "Building container-registry version ${registry_version}"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec container-registry $(MAKE) ${QQ}

.PHONY: registry/.git/pull
registry/.git/pull: registry/.git

registry-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${registry_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${registry_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${registry_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${registry_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${registry_dir} && $(MISE_INSTALL)
else
	@true
endif

registry_host.crt: registry_host.key

registry_host.key:
	$(Q)${OPENSSL} req -new -subj "/CN=${registry_host}/" -x509 -days 365 -newkey rsa:2048 -nodes -keyout "registry_host.key" -out "registry_host.crt" -addext "subjectAltName=DNS:${registry_host}"
	$(Q)chmod 600 $@

registry/storage:
	$(Q)mkdir -p $@

.PHONY: trust-docker-registry
trust-docker-registry: registry_host.crt
	$(Q)mkdir -p "${HOME}/.docker/certs.d/${registry_host}:${registry_port}"
	$(Q)rm -f "${HOME}/.docker/certs.d/${registry_host}:${registry_port}/ca.crt"
	$(Q)cp registry_host.crt "${HOME}/.docker/certs.d/${registry_host}:${registry_port}/ca.crt"
	$(Q)echo "Certificates have been copied to ~/.docker/certs.d/"
	$(Q)echo "Don't forget to restart Docker!"


.PHONY: registry-migrate
registry-migrate:
ifeq ($(registry_database_enabled), true)
	@echo
	@echo "${DIVIDER}"
	@echo "Applying any pending migrations"
	@echo "${DIVIDER}"
	$(Q)support/migrate-registry
else
	@true
endif
