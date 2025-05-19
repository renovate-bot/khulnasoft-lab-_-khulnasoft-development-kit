khulnasoft_dir = ${khulnasoft_development_root}/gitlab
khulnasoft_rake_cmd = $(in_gitlab) ${support_bundle_exec} rake
khulnasoft_git_cmd = git -C $(khulnasoft_dir)
in_gitlab = cd $(khulnasoft_dir) &&
default_branch ?= $(if $(khulnasoft_default_branch),$(khulnasoft_default_branch),master)

ifeq ($(asdf_opt_out),false)
	export PATH := $(shell support/update-path $(khulnasoft_dir))
endif

.PHONY: khulnasoft-setup
khulnasoft-setup: khulnasoft/.git gitlab-config gitlab-asdf-install .gitlab-bundle .gitlab-lefthook .gitlab-yarn .khulnasoft-translations

gitlab/doc/api/graphql/reference/khulnasoft_schema.json: .gitlab-bundle
	@echo
	@echo "${DIVIDER}"
	@echo "Generating gitlab GraphQL schema files"
	@echo "${DIVIDER}"
	$(Q)$(khulnasoft_rake_cmd) gitlab:graphql:schema:dump ${QQ}

khulnasoft/.git:
	@echo
	@echo "${DIVIDER}"
	@echo "Cloning ${khulnasoft_repo}"
	@echo "${DIVIDER}"
	$(Q)support/component-git-clone ${git_params} $(if $(realpath ${khulnasoft_repo}),--shared) ${khulnasoft_repo} ${khulnasoft_dir}

gitlab-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_dir} && $(MISE_INSTALL)
else
	@true
endif

gitlab-config: touch-examples gitlab/public/uploads
	$(Q)rake \
		gitlab/config/gitlab.yml \
		khulnasoft/config/database.yml \
		gitlab/config/cable.yml \
		gitlab/config/resque.yml \
		gitlab/config/redis.cache.yml \
		gitlab/config/redis.repository_cache.yml \
		gitlab/config/redis.queues.yml \
		gitlab/config/redis.shared_state.yml \
		gitlab/config/redis.trace_chunks.yml \
		gitlab/config/redis.rate_limiting.yml \
		gitlab/config/redis.sessions.yml \
		gitlab/config/vite.kdk.json \
		gitlab/config/puma.rb

gitlab/public/uploads:
	$(Q)mkdir $@

.PHONY: gitlab-bundle-prepare
gitlab-bundle-prepare:
	@echo
	@echo "${DIVIDER}"
	@echo "Setting up Ruby bundler"
	@echo "${DIVIDER}"
	${Q}. ./support/bootstrap-common.sh ; configure_ruby_bundler_for_gitlab

.gitlab-bundle: gitlab-bundle-prepare
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab Ruby gems"
	@echo "${DIVIDER}"
	${Q}$(support_bundle_install) $(khulnasoft_dir)
	$(Q)touch $@

ifeq ($(khulnasoft_lefthook_enabled),true)
.gitlab-lefthook:
	@echo
	@echo "${DIVIDER}"
	@echo "Enabling Lefthook for gitlab-org/gitlab"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) ${support_bundle_exec} lefthook install
	$(Q)touch $@
else
.gitlab-lefthook:
	@true
endif

.gitlab-yarn:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing gitlab-org/gitlab Node.js packages"
	@echo "${DIVIDER}"
	$(Q)$(in_gitlab) ${YARN} install --pure-lockfile ${QQ}
	$(Q)touch $@

.PHONY: khulnasoft-translations-unlock
khulnasoft-translations-unlock:
	$(Q)rm -f .khulnasoft-translations

.PHONY: khulnasoft-translations
khulnasoft-translations: khulnasoft-translations-timed

.PHONY: khulnasoft-translations-run
khulnasoft-translations-run: .khulnasoft-translations

.khulnasoft-translations:
	@echo
	@echo "${DIVIDER}"
	@echo "Generating gitlab-org/gitlab Rails translations"
	@echo "${DIVIDER}"
	$(Q)rake gitlab:recompile_translations
	$(Q)$(khulnasoft_git_cmd) checkout locale/*/gitlab.po
	$(Q)touch $@
