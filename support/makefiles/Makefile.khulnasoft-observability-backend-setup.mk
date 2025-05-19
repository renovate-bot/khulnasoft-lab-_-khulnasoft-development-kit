khulnasoft_gob_dir = ${khulnasoft_development_root}/khulnasoft-observability-backend

.PHONY: khulnasoft-observability-backend-setup
ifeq ($(khulnasoft_observability_backend_enabled),true)
khulnasoft-observability-backend-setup: khulnasoft-observability-backend/.git/pull
else
khulnasoft-observability-backend-setup:
	@true
endif

khulnasoft-observability-backend/.git:
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_observability_backend_repo} khulnasoft-observability-backend

.PHONY: khulnasoft-observability-backend/.git/pull
khulnasoft-observability-backend/.git/pull: khulnasoft-observability-backend/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating khulnasoft-org/opstrace"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_observability_backend khulnasoft-observability-backend main main
	@echo
	@echo "${DIVIDER}"
	@echo "Building GOB all-in-one binary - this can take a few minutes"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_gob_dir}/go/cmd/all-in-one && go build .
