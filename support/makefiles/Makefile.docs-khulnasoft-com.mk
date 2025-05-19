docs_khulnasoft_com_dir = ${khulnasoft_development_root}/docs-gitlab-com

make_docs = $(Q)make -C ${docs_khulnasoft_com_dir}

ifeq ($(docs_khulnasoft_com_enabled),true)
docs-gitlab-com-setup: ${docs_khulnasoft_com_dir}/.git docs-gitlab-com-deps gitlab-docs-yarn-build
else
docs-gitlab-com-setup:
	@true
endif

${docs_khulnasoft_com_dir}/.git:
	$(Q)support/component-git-clone ${git_params} ${docs_khulnasoft_com_repo} docs-gitlab-com

${docs_khulnasoft_com_dir}/.git/pull: ${docs_khulnasoft_com_dir}/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/docs-gitlab-com"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update docs_khulnasoft_com "${docs_khulnasoft_com_dir}" main main

.PHONY: docs-gitlab-com-deps
docs-gitlab-com-deps:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing dependencies for docs-gitlab-com"
	@echo "${DIVIDER}"
	$(make_docs) setup

ifeq ($(docs_khulnasoft_com_enabled),true)
gitlab-docs-yarn-build:
	@echo
	@echo "${DIVIDER}"
	@echo "Running vite"
	@echo "${DIVIDER}"
	$(Q)cd ${docs_khulnasoft_com_dir} && yarn build
else
gitlab-docs-yarn-build:
	@true
endif

.PHONY: docs-gitlab-com-update
ifeq ($(docs_khulnasoft_com_enabled),true)
docs-gitlab-com-update: docs-gitlab-com-update-timed
else
docs-gitlab-com-update:
	@true
endif

.PHONY: docs-gitlab-com-update-run
docs-gitlab-com-update-run: ${docs_khulnasoft_com_dir}/.git/pull docs-gitlab-com-deps gitlab-docs-yarn-build
