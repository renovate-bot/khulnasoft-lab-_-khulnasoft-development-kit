LYCHEE := $(shell command -v lychee 2> /dev/null)
MARKDOWNLINT := $(shell command -v markdownlint-cli2 2> /dev/null)

dev_checkmake_binary := $(or $(dev_checkmake_binary),$(shell command -v checkmake 2> /dev/null))

.PHONY: test
test: kdk_bundle_install
	@${support_bundle_exec} lefthook run pre-push

.PHONY: kdk_bundle_install
kdk_bundle_install:
	${Q}$(support_bundle_install) $(khulnasoft_development_root)

.PHONY: rubocop
ifeq ($(BUNDLE),)
rubocop:
	@echo "ERROR: Bundler is not installed, please ensure you've bootstrapped your machine. See https://github.com/khulnasoft-lab/khulnasoft-development-kit/blob/master/doc/index.md for more details"
	@false
else
rubocop: kdk_bundle_install
	@echo -n "RuboCop: "
	@${support_bundle_exec} $@ --config .rubocop-kdk.yml --parallel
endif

.PHONY: rspec
ifeq ($(BUNDLE),)
rspec:
	@echo "ERROR: Bundler is not installed, please ensure you've bootstrapped your machine. See https://github.com/khulnasoft-lab/khulnasoft-development-kit/blob/master/doc/index.md for more details"
	@false
else
rspec: kdk_bundle_install
	@echo -n "RSpec: "
	@${support_bundle_exec} $@ ${RSPEC_ARGS}
endif

.PHONY: lint
lint: vale markdownlint check-links

.PHONY: vale
vale:
	@support/dev/vale

.PHONY: yarn-install
yarn-install:
ifeq ($(YARN)),)
	@echo "ERROR: YARN is not installed, please ensure you've bootstrapped your machine. See https://github.com/khulnasoft-lab/khulnasoft-development-kit/blob/master/doc/index.md for more details"
	@false
else
	@[[ "${YARN}" ]] && ${YARN} install --silent --frozen-lockfile ${QQ}
endif

.PHONY: markdownlint
markdownlint:
	@echo -n "Markdownlint: "
	@markdownlint-cli2 'doc/**/*.md' && echo "OK"

# Doesn't check external links
.PHONY: check-links
check-links:
ifeq (${LYCHEE},)
	@echo "ERROR: Lychee not installed. For installation information, see: https://lychee.cli.rs/installation/"
else
	@echo -n "Check internal links: "
	@lychee --version
	@lychee --offline --include-fragments README.md doc/* && echo "OK"
endif

# Usage: make check-duplicates command="kdk update"
.PHONY: check-duplicates
check-duplicates:
	@echo "Checking for duplicated tasks:"
	@ruby ./support/compare.rb "$(command)"

.PHONY: shellcheck
shellcheck:
	@support/dev/shellcheck

.PHONY: checkmake
checkmake:
	@echo -n "Checkmake:   "
	@cat Makefile support/makefiles/*.mk > tmp/.makefile_combined
	@${dev_checkmake_binary} tmp/.makefile_combined && echo -e "\b\bOK"
	@rm -f tmp/.makefile_combined

.PHONY: verify-kdk-example-yml
verify-kdk-example-yml:
	@echo -n "Checking kdk.example.yml: "
	@support/ci/verify-kdk-example-yml && echo "OK"

.PHONY: verify-makefile-config
verify-makefile-config:
	@echo -n "Checking if support/makefiles/Makefile.config.mk is up-to-date: "
	@support/ci/verify-makefile-config && echo "OK"
