docs_khulnasoft_com_dir = ${khulnasoft_development_root}/docs-khulnasoft-com

make_docs = $(Q)make -C ${docs_khulnasoft_com_dir}

ifeq ($(docs_khulnasoft_com_enabled),true)
docs-khulnasoft-com-setup: ${docs_khulnasoft_com_dir}/.git docs-khulnasoft-com-deps khulnasoft-docs-yarn-build
else
docs-khulnasoft-com-setup:
	@true
endif

${docs_khulnasoft_com_dir}/.git:
	$(Q)support/component-git-clone ${git_params} ${docs_khulnasoft_com_repo} docs-khulnasoft-com

${docs_khulnasoft_com_dir}/.git/pull: ${docs_khulnasoft_com_dir}/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/docs-khulnasoft-com"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update docs_khulnasoft_com "${docs_khulnasoft_com_dir}" main main

.PHONY: docs-khulnasoft-com-deps
docs-khulnasoft-com-deps:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing dependencies for docs-khulnasoft-com"
	@echo "${DIVIDER}"
	$(make_docs) setup

ifeq ($(docs_khulnasoft_com_enabled),true)
khulnasoft-docs-yarn-build:
	@echo
	@echo "${DIVIDER}"
	@echo "Running vite"
	@echo "${DIVIDER}"
	$(Q)cd ${docs_khulnasoft_com_dir} && yarn build
else
khulnasoft-docs-yarn-build:
	@true
endif

.PHONY: docs-khulnasoft-com-update
ifeq ($(docs_khulnasoft_com_enabled),true)
docs-khulnasoft-com-update: docs-khulnasoft-com-update-timed
else
docs-khulnasoft-com-update:
	@true
endif

.PHONY: docs-khulnasoft-com-update-run
docs-khulnasoft-com-update-run: ${docs_khulnasoft_com_dir}/.git/pull docs-khulnasoft-com-deps khulnasoft-docs-yarn-build
