khulnasoft_ui_dir = ${khulnasoft_development_root}/khulnasoft-ui

.PHONY: khulnasoft-ui-setup
ifeq ($(khulnasoft_ui_enabled),true)
khulnasoft-ui-setup: khulnasoft-ui/.git khulnasoft-ui-asdf-install .khulnasoft-ui-yarn
else
khulnasoft-ui-setup:
	@true
endif

.PHONY: khulnasoft-ui-update
ifeq ($(khulnasoft_ui_enabled),true)
khulnasoft-ui-update: khulnasoft-ui-update-timed
else
khulnasoft-ui-update:
	@true
endif

.PHONY: khulnasoft-ui-update-run
khulnasoft-ui-update-run: khulnasoft-ui/.git khulnasoft-ui/.git/pull khulnasoft-ui-clean khulnasoft-ui-asdf-install .khulnasoft-ui-yarn

khulnasoft-ui/.git:
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_ui_repo} ${khulnasoft_ui_dir} ${QQ}

khulnasoft-ui/.git/pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/khulnasoft-ui"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_ui "${khulnasoft_ui_dir}" main main

.PHONY: khulnasoft-ui-clean
khulnasoft-ui-clean:
	@rm -f .khulnasoft-ui-yarn

khulnasoft-ui-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_ui_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_ui_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_ui_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_ui_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_ui_dir} && $(MISE_INSTALL)
else
	@true
endif

.khulnasoft-ui-yarn:
ifeq ($(YARN),)
	@echo "ERROR: YARN is not installed, please ensure you've bootstrapped your machine. See https://github.com/khulnasoft-lab/khulnasoft-development-kit/blob/master/doc/index.md for more details"
	@false
else
	@echo
	@echo "${DIVIDER}"
	@echo "Installing khulnasoft-org/khulnasoft-ui Node.js packages"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_development_root}/khulnasoft-ui && ${YARN} install --silent ${QQ}
	$(Q)cd ${khulnasoft_development_root}/khulnasoft-ui && ${YARN} build --silent ${QQ}
	$(Q)touch $@
endif
