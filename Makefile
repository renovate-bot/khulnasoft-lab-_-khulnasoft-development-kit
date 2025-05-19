.NOTPARALLEL:

START_TIME := $(shell date "+%s")

MAKEFLAGS += --no-print-directory

DIVIDER = "--------------------------------------------------------------------------------"

SHELL = bin/kdk-shell
ASDF := $(shell command -v asdf 2> /dev/null)
RAKE := $(shell command -v rake 2> /dev/null)
BUNDLE := $(shell command -v bundle 2> /dev/null)
YARN := $(shell command -v yarn 2> /dev/null)

# Speed up Go module downloads
export GOPROXY ?= https://proxy.golang.org|https://proxy.golang.org

NO_RAKE_TARGETS := bootstrap bootstrap-packages lint list
RAKE_REQUIRED := $(filter-out $(NO_RAKE_TARGETS), $(MAKECMDGOALS))

# Generate a Makefile from Ruby and include it
ifdef RAKE_REQUIRED
ifndef RAKE
$(error "ERROR: Cannot find 'rake'. Please run 'make bootstrap'.")
endif
ifndef SKIP_GENERATE_KDK_CONFIG_MK
RETCODE := $(shell rake kdk-config.mk > /dev/null; echo $$?)
ifneq ($(RETCODE), 0)
  $(error rake failed to generate kdk-config.mk)
endif
endif
include kdk-config.mk
endif

ASDF_INSTALL := env -u MAKELEVEL asdf install
MISE_INSTALL := env -u MAKELEVEL mise install -y

###############################################################################
# Include all support/makefiles/*.mk files here                               #
###############################################################################

include support/makefiles/*.mk

ifeq ($(platform),darwin)
OPENSSL_PREFIX := $(shell brew --prefix openssl)
OPENSSL := ${OPENSSL_PREFIX}/bin/openssl
else
OPENSSL := $(shell command -v openssl 2> /dev/null)
endif

support_bundle_install = $(khulnasoft_development_root)/support/bundle-install
support_bundle_exec = $(khulnasoft_development_root)/support/bundle-exec

# `make` verbosity mode, borrowed from
# https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/Makefile#n87
# To show more messages, run it as `make [target] kdk_debug=true`
ifeq ($(kdk_debug),true)
	Q =
	QQ =
else
	Q = @
	QQ = > /dev/null
endif

QQerr = 2> /dev/null

ifeq ($(shallow_clone),true)
# https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt
git_params = --depth=1
else ifeq ($(blobless_clone),false)
git_params =
else
# https://git-scm.com/docs/git-clone#Documentation/git-clone.txt---filterltfilter-specgt
git_params = --filter=blob:none
endif

# List Makefile targets
.PHONY: list
list:
	@make -qp | awk -F':' '/^[a-zA-Z0-9][^$$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sort -u

# This is used by `kdk install`
#
# When KhulnaSoft boots, it checks to ensure the version of khulnasoft-shell it expects
# (based off of https://gitlab.com/gitlab-org/gitlab/-/blob/b99664deef4af88ef33bcd0abef8b0845a81e00f/KHULNASOFT_SHELL_VERSION)
# matches what's checkout under <KDK_ROOT>/khulnasoft-shell (https://gitlab.com/gitlab-org/gitlab/-/blob/b99664deef4af88ef33bcd0abef8b0845a81e00f/config/initializers/5_backend.rb#L8).
# We run khulnasoft-shell-setup here before khulnasoft-setup to ensure KhulnaSoft is happy.
# We also need to run khulnasoft/.git _prior_ to khulnasoft-shell-setup because it
# needs access to <KDK_ROOT>/khulnasoft/KHULNASOFT_SHELL_VERSION
#
.PHONY: all
all: preflight-checks \
kdk_bundle_install \
khulnasoft/.git \
khulnasoft-shell-setup \
khulnasoft-setup \
gitaly-setup \
khulnasoft-topology-service-setup \
ensure-databases-setup \
Procfile \
jaeger-setup \
postgresql \
openssh-setup \
nginx-setup \
registry-setup \
elasticsearch-setup \
khulnasoft-runner-setup \
runner-setup \
geo-config \
khulnasoft-http-router-setup \
docs-khulnasoft-com-setup \
khulnasoft-elasticsearch-indexer-setup \
khulnasoft-k8s-agent-setup \
khulnasoft-pages-setup \
khulnasoft-ui-setup \
khulnasoft-workhorse-setup \
khulnasoft-zoekt-setup \
khulnasoft-ai-gateway-setup \
grafana-setup \
object-storage-setup \
openldap-setup \
pgvector-setup \
prom-setup \
snowplow-micro-setup \
siphon-setup \
nats-setup \
duo-workflow-executor-setup \
postgresql-replica-setup \
postgresql-replica-2-setup \
kdk-reconfigure-task

# This is used by `kdk install`
#
.PHONY: install
install: start-task all post-install-task start

# This is used by `kdk update`
#
# Pull `khulnasoft` directory first, since its dependencies are linked from there.
.PHONY: update
update:
	@echo -e '\033[0;33mDEPRECATION WARNING\033[0m:'
	@echo -e '\033[0;33mDEPRECATION WARNING\033[0m: `make update` is deprecated, use `kdk update` instead.'
	@echo -e '\033[0;33mDEPRECATION WARNING\033[0m:'
	KDK_SELF_UPDATE=0 kdk update

# This is used by `kdk reconfigure`
.PHONY: reconfigure
reconfigure:
	@rake reconfigure

.PHONY: start-task
start-task:
	@support/dev/makefile-timeit start

.PHONY: post-task
post-task:
	@echo
	@echo "${DIVIDER}"
	@echo "$(SUCCESS_MESSAGE) successfully as of $$(date +"%Y-%m-%d %T")"
	@support/dev/makefile-timeit summarize
	@echo "${DIVIDER}"

.PHONY: post-install-task
post-install-task:
	$(Q)$(eval SUCCESS_MESSAGE := "Installed")
	$(Q)$(MAKE) post-task SUCCESS_MESSAGE="$(SUCCESS_MESSAGE)"

.PHONY: post-update-task
post-update-task:
	$(Q)$(eval SUCCESS_MESSAGE := "Updated")
	$(Q)$(MAKE) post-task SUCCESS_MESSAGE="$(SUCCESS_MESSAGE)"

.PHONY: clean
clean:
	@true

self-update: unlock-dependency-installers
	@echo
	@echo "${DIVIDER}"
	@echo "Running self-update on KDK"
	@echo "${DIVIDER}"
	$(Q)git stash ${QQ}
	$(Q)support/self-update-git-worktree ${QQ}

.PHONY: touch-examples
touch-examples:
	$(Q)touch \
	$$(find support/templates -name "*.erb" -not -path "*/khulnasoft-pages-secret.erb" -not -path "*/khulnasoft-kas-websocket-token-secret.erb" -not -path "*/khulnasoft-kas-autoflow-temporal-workflow-data-encryption-secret.erb") > /dev/null 2>&1 || true

unlock-dependency-installers:
	$(Q)rm -f \
	.khulnasoft-bundle \
	.khulnasoft-shell-bundle \
	.khulnasoft-yarn \
	.khulnasoft-ui-yarn \
	.khulnasoft-lefthook

kdk.yml:
	$(Q)touch $@

.PHONY: rake
rake:
	$(Q)command -v $@ ${QQ} || gem install $@

.PHONY: ensure-databases-setup
ensure-databases-setup: Procfile postgresql/data redis/redis.conf ensure-databases-running

.PHONY: ensure-databases-running
ensure-databases-running:
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring necessary data services are running"
	@echo "${DIVIDER}"
	$(Q)kdk start rails-migration-dependencies

.PHONY: diff-config
diff-config:
	$(Q)kdk $@

.PHONY: start
start:
	@echo
	$(Q)kdk start

.PHONY: kdk-reconfigure-task
kdk-reconfigure-task: touch-examples
	@echo
	@echo "${DIVIDER}"
	@echo "Ensuring KDK managed configuration files are up-to-date"
	@echo "${DIVIDER}"
	$(Q)rake generate_config_files

migrate-to-mise:
	@bundle exec rake mise:migrate
