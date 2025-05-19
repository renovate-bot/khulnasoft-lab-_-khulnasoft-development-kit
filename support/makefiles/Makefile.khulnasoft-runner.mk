khulnasoft_runner_dir = ${khulnasoft_development_root}/gitlab-runner

# For the runner service, not the repository
.PHONY: runner-setup
runner-setup: gitlab-runner-config.toml

.PHONY: gitlab-runner-setup
ifeq ($(khulnasoft_runner_enabled),true)
gitlab-runner-setup: gitlab-runner/.git/pull
else
gitlab-runner-setup:
	@true
endif

.PHONY: gitlab-runner-update
ifeq ($(khulnasoft_runner_enabled),true)
gitlab-runner-update: gitlab-runner/.git/pull
else
gitlab-runner-update:
	@true
endif

gitlab-runner-asdf-install:
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

gitlab-runner/.git:
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_runner_repo} gitlab-runner

gitlab-runner/.git/pull: gitlab-runner/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-runner"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_runner "${khulnasoft_runner_dir}" main main
