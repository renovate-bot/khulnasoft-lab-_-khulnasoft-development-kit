khulnasoft_nats_dir = ${khulnasoft_development_root}/nats
NATS_VERSION := 2.10.19
NATS_BINARY := ${khulnasoft_nats_dir}/nats-server

.PHONY: nats-setup
ifeq ($(nats_enabled),true)
nats-setup: nats-setup-timed nats-setup-run
else
nats-setup:
	@true
endif

.PHONY: nats-setup-run
nats-setup-run: nats-common-setup

.PHONY: nats-common-setup
nats-common-setup: nats-download

.PHONY: nats-download
nats-download:
	$(Q)mkdir -p ${khulnasoft_nats_dir}
	$(Q)if [ ! -f "${NATS_BINARY}" ] || [ "$$(${NATS_BINARY} -version 2>&1 | awk '{print $$2}')" != "v${NATS_VERSION}" ]; then \
		cd ${khulnasoft_nats_dir} && curl -sf https://binaries.nats.dev/nats-io/nats-server/v2@v${NATS_VERSION} | sh; \
	else \
		echo "NATS server v${NATS_VERSION} is already installed."; \
	fi

.PHONY: nats-update
ifeq ($(nats_enabled),true)
nats-update: nats-update-timed
else
nats-update:
	@true
endif

.PHONY: nats-update-run
nats-update-run: nats-common-setup
