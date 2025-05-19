khulnasoft_ai_gateway_dir = ${khulnasoft_development_root}/khulnasoft-ai-gateway

.PHONY: khulnasoft-ai-gateway-setup
ifeq ($(khulnasoft_ai_gateway_enabled),true)
khulnasoft-ai-gateway-setup: khulnasoft-ai-gateway-setup-timed
else
khulnasoft-ai-gateway-setup:
	@true
endif

.PHONY: khulnasoft-ai-gateway-setup-run
khulnasoft-ai-gateway-setup-run: khulnasoft-ai-gateway/.git khulnasoft-ai-common-setup khulnasoft-ai-gateway-gcloud-setup

.PHONY: khulnasoft-ai-common-setup
khulnasoft-ai-common-setup: khulnasoft-ai-gateway/.env khulnasoft-ai-gateway-llm-cache khulnasoft-ai-gateway-asdf-install khulnasoft-ai-gateway-poetry-install

khulnasoft-ai-gateway/.env:
	$(Q)cd ${khulnasoft_ai_gateway_dir} && cp example.env .env
	$(Q)cd ${khulnasoft_ai_gateway_dir} && echo -e "\n# KDK additions" >> .env

.PHONY: khulnasoft-ai-gateway-poetry-install
khulnasoft-ai-gateway-poetry-install:
	@echo
	@echo "${DIVIDER}"
	@echo "Performing poetry steps for ${khulnasoft_ai_gateway_dir}"
	@echo "${DIVIDER}"
	# Set Python version for poetry to fix Python upgrades.
	$(Q)egrep '^python ' ${khulnasoft_ai_gateway_dir}/.tool-versions | awk '{ print $$2 }' | support/asdf-exec ${khulnasoft_ai_gateway_dir} xargs -L 1 poetry env use
	$(Q)support/asdf-exec ${khulnasoft_ai_gateway_dir} poetry install

.PHONY: khulnasoft-ai-gateway-gcloud-setup
khulnasoft-ai-gateway-gcloud-setup:
	@echo
	@echo "${DIVIDER}"
	@echo "Logging into Google Cloud for ${khulnasoft_ai_gateway_dir}"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_ai_gateway_dir} && gcloud auth application-default login

.PHONY: khulnasoft-ai-gateway-update
ifeq ($(khulnasoft_ai_gateway_enabled),true)
khulnasoft-ai-gateway-update: khulnasoft-ai-gateway-update-timed
else
khulnasoft-ai-gateway-update:
	@true
endif

.PHONY: khulnasoft-ai-gateway-update-run
khulnasoft-ai-gateway-update-run: khulnasoft-ai-gateway/.git/pull khulnasoft-ai-common-setup

.PHONY: khulnasoft-ai-gateway-asdf-install
khulnasoft-ai-gateway-asdf-install:
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

khulnasoft-ai-gateway/.git:
	$(Q)GIT_REVISION="${khulnasoft_ai_gateway_version}" support/component-git-clone ${git_params} ${khulnasoft_ai_gateway_repo} khulnasoft-ai-gateway

.PHONY: khulnasoft-ai-gateway/.git/pull
khulnasoft-ai-gateway/.git/pull: khulnasoft-ai-gateway/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/khulnasoft-ai-gateway"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_ai_gateway khulnasoft-ai-gateway "${khulnasoft_ai_gateway_version}" main

.PHONY: khulnasoft-ai-gateway-llm-cache
ifeq ($(duo_workflow_llm_cache),true)
khulnasoft-ai-gateway-llm-cache: khulnasoft-ai-gateway/.env
	# Add LLM_CACHE=true only if no LLM_CACHE line exists. Also add
	# newline just in case it does not end in a newline already
	grep -q 'LLM_CACHE' khulnasoft-ai-gateway/.env || echo -e '\nLLM_CACHE=true' >> khulnasoft-ai-gateway/.env
else
khulnasoft-ai-gateway-llm-cache:
	# Remove the LLM_CACHE line from the file
	grep -v LLM_CACHE khulnasoft-ai-gateway/.env > khulnasoft-ai-gateway/.env.temp && mv khulnasoft-ai-gateway/.env.temp khulnasoft-ai-gateway/.env
endif
