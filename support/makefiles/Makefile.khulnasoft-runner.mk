khulnasoft_runner_dir = ${khulnasoft_development_root}/khulnasoft-runner

# For the runner service, not the repository
.PHONY: runner-setup
runner-setup: khulnasoft-runner-config.toml

.PHONY: khulnasoft-runner-setup
ifeq ($(khulnasoft_runner_enabled),true)
khulnasoft-runner-setup: khulnasoft-runner/.git/pull
else
khulnasoft-runner-setup:
	@true
endif

.PHONY: khulnasoft-runner-update
ifeq ($(khulnasoft_runner_enabled),true)
khulnasoft-runner-update: khulnasoft-runner/.git/pull
else
khulnasoft-runner-update:
	@true
endif

khulnasoft-runner-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_runner_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_runner_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_runner_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_runner_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_runner_dir} && $(MISE_INSTALL)
else
	@true
endif

khulnasoft-runner/.git:
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_runner_repo} khulnasoft-runner

khulnasoft-runner/.git/pull: khulnasoft-runner/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/khulnasoft-runner"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_runner "${khulnasoft_runner_dir}" main main
