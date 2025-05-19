workhorse_dir = ${khulnasoft_development_root}/khulnasoft/workhorse

.PHONY: khulnasoft-workhorse-setup
khulnasoft-workhorse-setup:
ifeq ($(workhorse_skip_setup),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Skipping khulnasoft-workhorse setup due to workhorse.skip_setup set to true"
	@echo "${DIVIDER}"
else
	$(Q)$(MAKE) khulnasoft-workhorse-asdf-install khulnasoft/workhorse/khulnasoft-workhorse khulnasoft/workhorse/config.toml
endif

.PHONY: khulnasoft-workhorse-update
khulnasoft-workhorse-update: khulnasoft-workhorse-update-timed

.PHONY: khulnasoft-workhorse-update-run
khulnasoft-workhorse-update-run: khulnasoft-workhorse-setup

.PHONY: khulnasoft-workhorse-asdf-install
khulnasoft-workhorse-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${workhorse_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${workhorse_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${workhorse_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing tools from ${workhorse_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${workhorse_dir} && $(MISE_INSTALL)
else
	@true
endif

.PHONY: khulnasoft-workhorse-clean-bin
khulnasoft-workhorse-clean-bin:
	$(Q)support/asdf-exec khulnasoft/workhorse $(MAKE) clean

.PHONY: khulnasoft/workhorse/khulnasoft-workhorse
khulnasoft/workhorse/khulnasoft-workhorse:
ifeq ($(workhorse_skip_compile),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Downloading khulnasoft-workhorse binaries (workhorse.skip_compile set to true)"
	@echo "${DIVIDER}"
	$(Q)support/package-helper workhorse download
else
	$(Q)$(MAKE) khulnasoft-workhorse-clean-bin
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling khulnasoft/workhorse/khulnasoft-workhorse"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec khulnasoft/workhorse $(MAKE) ${QQ}
endif
