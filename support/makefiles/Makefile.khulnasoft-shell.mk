khulnasoft_shell_clone_dir = gitlab-shell
khulnasoft_shell_dir = ${khulnasoft_development_root}/${khulnasoft_shell_clone_dir}

.PHONY: gitlab-shell-setup
gitlab-shell-setup:  localhost.crt
ifeq ($(khulnasoft_shell_skip_setup),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Skipping gitlab-shell setup due to option khulnasoft_shell.skip_setup set to true"
	@echo "${DIVIDER}"
else
	$(Q)$(MAKE) gitlab-shell/.git gitlab-shell-asdf-install gitlab-shell/config.yml .gitlab-shell-bundle gitlab-shell/.khulnasoft_shell_secret $(sshd_hostkeys) gitlab-shell/bin/gitlab-shell
endif

.PHONY: gitlab-shell-update
gitlab-shell-update: gitlab-shell-update-timed

.PHONY: gitlab-shell-update-run
gitlab-shell-update-run: gitlab-shell-git-pull gitlab-shell-setup

.PHONY: gitlab-shell-git-pull
gitlab-shell-git-pull: gitlab-shell-git-pull-timed

.PHONY: gitlab-shell-git-pull-run
gitlab-shell-git-pull-run:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-shell to ${khulnasoft_shell_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_shell "${khulnasoft_development_root}/gitlab-shell" "${khulnasoft_shell_version}" main

gitlab-shell/.git:
	$(Q)GIT_REVISION="${khulnasoft_shell_version}" support/component-git-clone ${git_params} ${khulnasoft_shell_repo} ${khulnasoft_shell_clone_dir}

.PHONY: .gitlab-shell-bundle
.gitlab-shell-bundle:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab-shell Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(khulnasoft_shell_dir)
	$(Q)touch $@

.PHONY: gitlab-shell/.khulnasoft_shell_secret
gitlab-shell/.khulnasoft_shell_secret:
	$(Q)ln -nfs ${khulnasoft_development_root}/gitlab/.khulnasoft_shell_secret $@

.PHONY: gitlab-shell-asdf-install
gitlab-shell-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_shell_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_shell_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_shell_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_shell_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_shell_dir} && $(MISE_INSTALL)
else
	@true
endif

.PHONY: gitlab-shell/bin/gitlab-shell
gitlab-shell/bin/gitlab-shell:
ifeq ($(khulnasoft_shell_skip_compile),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Downloading gitlab-shell binaries (khulnasoft_shell.skip_compile set to true)"
	@echo "${DIVIDER}"
	$(Q)support/package-helper khulnasoft_shell download
else
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling gitlab-shell/bin/gitlab-shell"
	@echo "${DIVIDER}"
	$(Q)make -C gitlab-shell build ${QQ}
endif
