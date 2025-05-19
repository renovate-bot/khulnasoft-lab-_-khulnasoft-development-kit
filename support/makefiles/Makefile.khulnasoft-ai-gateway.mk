khulnasoft_ai_gateway_dir = ${khulnasoft_development_root}/gitlab-ai-gateway

.PHONY: gitlab-ai-gateway-setup
ifeq ($(khulnasoft_ai_gateway_enabled),true)
gitlab-ai-gateway-setup: gitlab-ai-gateway-setup-timed
else
gitlab-ai-gateway-setup:
	@true
endif

.PHONY: gitlab-ai-gateway-setup-run
gitlab-ai-gateway-setup-run: gitlab-ai-gateway/.git gitlab-ai-common-setup gitlab-ai-gateway-gcloud-setup

.PHONY: gitlab-ai-common-setup
gitlab-ai-common-setup: gitlab-ai-gateway/.env gitlab-ai-gateway-llm-cache gitlab-ai-gateway-asdf-install gitlab-ai-gateway-poetry-install

gitlab-ai-gateway/.env:
	$(Q)cd ${khulnasoft_ai_gateway_dir} && cp example.env .env
	$(Q)cd ${khulnasoft_ai_gateway_dir} && echo -e "\n# KDK additions" >> .env

.PHONY: gitlab-ai-gateway-poetry-install
gitlab-ai-gateway-poetry-install:
	@echo
	@echo "${DIVIDER}"
	@echo "Performing poetry steps for ${khulnasoft_ai_gateway_dir}"
	@echo "${DIVIDER}"
	# Set Python version for poetry to fix Python upgrades.
	$(Q)egrep '^python ' ${khulnasoft_ai_gateway_dir}/.tool-versions | awk '{ print $$2 }' | support/asdf-exec ${khulnasoft_ai_gateway_dir} xargs -L 1 poetry env use
	$(Q)support/asdf-exec ${khulnasoft_ai_gateway_dir} poetry install

.PHONY: gitlab-ai-gateway-gcloud-setup
gitlab-ai-gateway-gcloud-setup:
	@echo
	@echo "${DIVIDER}"
	@echo "Logging into Google Cloud for ${khulnasoft_ai_gateway_dir}"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_ai_gateway_dir} && gcloud auth application-default login

.PHONY: gitlab-ai-gateway-update
ifeq ($(khulnasoft_ai_gateway_enabled),true)
gitlab-ai-gateway-update: gitlab-ai-gateway-update-timed
else
gitlab-ai-gateway-update:
	@true
endif

.PHONY: gitlab-ai-gateway-update-run
gitlab-ai-gateway-update-run: gitlab-ai-gateway/.git/pull gitlab-ai-common-setup

.PHONY: gitlab-ai-gateway-asdf-install
gitlab-ai-gateway-asdf-install:
ifeq ($(asdf_opt_out),false)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing asdf tools from ${khulnasoft_ai_gateway_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_ai_gateway_dir} && egrep -v '^#' .tool-versions | awk '{ print $$1 }' | xargs -L 1 asdf plugin add
	@# glcloud requires python to be installed already so we need to explicitly install the required python version first
	$(Q)cd ${khulnasoft_ai_gateway_dir} && egrep '^python ' .tool-versions | awk '{ print $$1 " " $$2 }' | xargs -L 1 $(ASDF_INSTALL)
	@# markdownlint-cli2 requires nodejs to be installed already so we need to explicitly install the required nodejs version first
	$(Q)cd ${khulnasoft_ai_gateway_dir} && egrep '^nodejs ' .tool-versions | awk '{ print $$1 " " $$2 }' | xargs -L 1 $(ASDF_INSTALL)
	$(Q)cd ${khulnasoft_ai_gateway_dir} && ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="${khulnasoft_ai_gateway_dir}/.tool-versions" $(ASDF_INSTALL)
else ifeq ($(mise_enabled),true)
	@echo
	@echo "${DIVIDER}"
	@echo "Installing mise tools from ${khulnasoft_ai_gateway_dir}/.tool-versions"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_ai_gateway_dir} && $(MISE_INSTALL)
else
	@true
endif

gitlab-ai-gateway/.git:
	$(Q)GIT_REVISION="${khulnasoft_ai_gateway_version}" support/component-git-clone ${git_params} ${khulnasoft_ai_gateway_repo} gitlab-ai-gateway

.PHONY: gitlab-ai-gateway/.git/pull
gitlab-ai-gateway/.git/pull: gitlab-ai-gateway/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/gitlab-ai-gateway"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_ai_gateway gitlab-ai-gateway "${khulnasoft_ai_gateway_version}" main

.PHONY: gitlab-ai-gateway-llm-cache
ifeq ($(duo_workflow_llm_cache),true)
gitlab-ai-gateway-llm-cache: gitlab-ai-gateway/.env
	# Add LLM_CACHE=true only if no LLM_CACHE line exists. Also add
	# newline just in case it does not end in a newline already
	grep -q 'LLM_CACHE' gitlab-ai-gateway/.env || echo -e '\nLLM_CACHE=true' >> gitlab-ai-gateway/.env
else
gitlab-ai-gateway-llm-cache:
	# Remove the LLM_CACHE line from the file
	grep -v LLM_CACHE gitlab-ai-gateway/.env > gitlab-ai-gateway/.env.temp && mv gitlab-ai-gateway/.env.temp gitlab-ai-gateway/.env
endif
