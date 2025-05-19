khulnasoft_shell_clone_dir = khulnasoft-shell
khulnasoft_shell_dir = ${khulnasoft_development_root}/${khulnasoft_shell_clone_dir}

.PHONY: khulnasoft-shell-setup
khulnasoft-shell-setup:  localhost.crt
ifeq ($(khulnasoft_shell_skip_setup),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Skipping khulnasoft-shell setup due to option khulnasoft_shell.skip_setup set to true"
	@echo "${DIVIDER}"
else
	$(Q)$(MAKE) khulnasoft-shell/.git khulnasoft-shell-asdf-install khulnasoft-shell/config.yml .khulnasoft-shell-bundle khulnasoft-shell/.khulnasoft_shell_secret $(sshd_hostkeys) khulnasoft-shell/bin/khulnasoft-shell
endif

.PHONY: khulnasoft-shell-update
khulnasoft-shell-update: khulnasoft-shell-update-timed

.PHONY: khulnasoft-shell-update-run
khulnasoft-shell-update-run: khulnasoft-shell-git-pull khulnasoft-shell-setup

.PHONY: khulnasoft-shell-git-pull
khulnasoft-shell-git-pull: khulnasoft-shell-git-pull-timed

.PHONY: khulnasoft-shell-git-pull-run
khulnasoft-shell-git-pull-run:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/khulnasoft-shell to ${khulnasoft_shell_version}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_shell "${khulnasoft_development_root}/khulnasoft-shell" "${khulnasoft_shell_version}" main

khulnasoft-shell/.git:
	$(Q)GIT_REVISION="${khulnasoft_shell_version}" support/component-git-clone ${git_params} ${khulnasoft_shell_repo} ${khulnasoft_shell_clone_dir}

.PHONY: .khulnasoft-shell-bundle
.khulnasoft-shell-bundle:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing khulnasoft-org/khulnasoft-shell Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(khulnasoft_shell_dir)
	$(Q)touch $@

.PHONY: khulnasoft-shell/.khulnasoft_shell_secret
khulnasoft-shell/.khulnasoft_shell_secret:
	$(Q)ln -nfs ${khulnasoft_development_root}/khulnasoft/.khulnasoft_shell_secret $@

.PHONY: khulnasoft-shell-asdf-install
khulnasoft-shell-asdf-install:
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

.PHONY: khulnasoft-shell/bin/khulnasoft-shell
khulnasoft-shell/bin/khulnasoft-shell:
ifeq ($(khulnasoft_shell_skip_compile),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Downloading khulnasoft-shell binaries (khulnasoft_shell.skip_compile set to true)"
	@echo "${DIVIDER}"
	$(Q)support/package-helper khulnasoft_shell download
else
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling khulnasoft-shell/bin/khulnasoft-shell"
	@echo "${DIVIDER}"
	$(Q)make -C khulnasoft-shell build ${QQ}
endif
