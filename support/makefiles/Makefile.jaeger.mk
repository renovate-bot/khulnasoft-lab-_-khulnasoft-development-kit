ifeq ($(jaeger_server_enabled),true)
.PHONY: jaeger-setup
jaeger-setup: jaeger/jaeger-${jaeger_version}/jaeger-all-in-one
else
.PHONY: jaeger-setup
jaeger-setup:
	@true
endif

jaeger/jaeger-${jaeger_version}/jaeger-all-in-one:
	@echo
	@echo "${DIVIDER}"
	@echo "Installing jaeger ${jaeger_version}"
	@echo "${DIVIDER}"

	$(Q)mkdir -p jaeger-artifacts

	@# To save disk space, delete old versions of the download,
	@# but to save bandwidth keep the current version....
	$(Q)find jaeger-artifacts ! -path "jaeger-artifacts/jaeger-${jaeger_version}.tar.gz" -type f -exec rm -f {} + -print

	$(Q)./support/download-jaeger "${jaeger_version}" "jaeger-artifacts/jaeger-${jaeger_version}.tar.gz"

	$(Q)mkdir -p "jaeger/jaeger-${jaeger_version}"
	$(Q)tar -xf "jaeger-artifacts/jaeger-${jaeger_version}.tar.gz" -C "jaeger/jaeger-${jaeger_version}" --strip-components 1

.PHONY: jaeger-update
jaeger-update: jaeger-update-timed

.PHONY: jaeger-update-run
jaeger-update-run: jaeger-setup
