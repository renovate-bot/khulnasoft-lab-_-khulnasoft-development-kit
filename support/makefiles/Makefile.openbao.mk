openbao_internal_dir = ${khulnasoft_development_root}/openbao-internal
openbao_dir = ${khulnasoft_development_root}/openbao

.PHONY: openbao-setup
ifeq ($(openbao_enabled),true)
openbao-setup: openbao-setup-timed
else
openbao-setup:
	@true
endif

.PHONY: openbao-setup-run
openbao-setup-run: openbao-internal/.git openbao-compile

# Initial clone and submodule setup
openbao-internal/.git:
	$(Q)support/component-git-clone ${git_params} ${openbao_internal_repo} openbao-internal
	$(Q)cd ${openbao_internal_dir} && git submodule init && git submodule update
	$(Q)mkdir -p ${openbao_dir}
	$(Q)mkdir -p ${openbao_dir}/data

.PHONY: openbao-compile
openbao-compile:
	@echo
	@echo "${DIVIDER}"
	@echo "Compiling openbao using internal build system"
	@echo "${DIVIDER}"
	$(Q)support/asdf-exec ${openbao_internal_dir} make clean build
	$(Q)mkdir -p ${openbao_dir}/bin
	$(Q)cp ${openbao_internal_dir}/bin/bao ${openbao_dir}/bin/bao

.PHONY: openbao-update
ifeq ($(openbao_enabled),true)
openbao-update: openbao-update-timed
else
openbao-update:
	@true
endif

.PHONY: openbao-update-run
openbao-update-run: openbao-internal-pull openbao-compile

# Update the repo
.PHONY: openbao-internal-pull
openbao-internal-pull:
	@echo
	@echo "${DIVIDER}"
	@echo "Updating openbao-internal"
	@echo "${DIVIDER}"
	$(Q)support/component-git-update openbao-internal openbao-internal "" main
	$(Q)cd ${openbao_internal_dir} && git submodule update
