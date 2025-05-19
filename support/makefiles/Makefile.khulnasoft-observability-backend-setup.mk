khulnasoft_gob_dir = ${khulnasoft_development_root}/gitlab-observability-backend

.PHONY: gitlab-observability-backend-setup
ifeq ($(khulnasoft_observability_backend_enabled),true)
gitlab-observability-backend-setup: gitlab-observability-backend/.git/pull
else
gitlab-observability-backend-setup:
	@true
endif

gitlab-observability-backend/.git:
	$(Q)support/component-git-clone ${git_params} ${khulnasoft_observability_backend_repo} gitlab-observability-backend

.PHONY: gitlab-observability-backend/.git/pull
gitlab-observability-backend/.git/pull: gitlab-observability-backend/.git
	@echo
	@echo "${DIVIDER}"
	@echo "Updating gitlab-org/opstrace"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update khulnasoft_observability_backend gitlab-observability-backend main main
	@echo
	@echo "${DIVIDER}"
	@echo "Building GOB all-in-one binary - this can take a few minutes"
	@echo "${DIVIDER}"
	$(Q)cd ${khulnasoft_gob_dir}/go/cmd/all-in-one && go build .
