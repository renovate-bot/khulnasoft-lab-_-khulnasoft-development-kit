#!/usr/bin/env bash

# This script needs to be run to configure kdk.yml

# It takes a look at the environment variables set by kubernetes
# and the workspace and attempts to configure kdk.yml accordingly.

set -eo pipefail

# See https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-SECONDS for the usage of seconds.
SECONDS=0

LOG_FILE="execution_times.log"
PROJECT_PATH=/projects/khulnasoft-development-kit
WORKSPACE_DIR_NAME=/workspace

measure_time() {
  local start=$SECONDS
  "$@"
  local duration=$((SECONDS - start))
  echo "$1: $duration seconds" >> "$LOG_FILE"
}

check_inotify() {
  INOTIFY_WATCHES=$(cat /proc/sys/fs/inotify/max_user_watches)
  INOTIFY_WATCHES_THRESHOLD=524288
  if [[ ${INOTIFY_WATCHES} -lt ${INOTIFY_WATCHES_THRESHOLD} ]]; then
    echo "fs.inotify.max_user_watches is less than ${INOTIFY_WATCHES_THRESHOLD}. Please set this on your node."
    echo "See https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/307 and"
    echo "https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/doc/advanced.md#install-dependencies-for-other-linux-distributions"
    echo "for details."

    exit 1
  fi
}

install_gems() {
  cd "${PROJECT_PATH}"
  echo "Installing Gems in ${PROJECT_PATH}"
  bundle install
  cd gitlab
  echo "Installing Gems in ${PROJECT_PATH}/gitlab"
  bundle install
  cd "${PROJECT_PATH}"
}

clone_gitlab() {
  echo "Cloning gitlab-org/gitlab"
  make khulnasoft/.git
  cp "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/secrets.yml" gitlab/config
}

copy_items_from_bootstrap() {
  interesting_items=(
    ".cache"
    "clickhouse"
    "consul"
    "kdk-config.mk"
    "gitaly"
    ".gitlab-bundle"
    ".gitlab-lefthook"
    "gitlab-pages"
    "gitlab-runner-config.toml"
    "gitlab-shell"
    ".gitlab-shell-bundle"
    ".khulnasoft-translations"
    ".gitlab-yarn" 
    "localhost.crt"
    "localhost.key"
    "log"
    "pgbouncers"
    "postgresql"
    "Procfile"
    "registry"
    "registry_host.crt"
    "registry_host.key"
    "repositories"
    "services"
    "sv"
  )
  
  for item in "${interesting_items[@]}"; do
    echo "Moving bootstrapped KDK item: ${item}"
    rm -rf "${PROJECT_PATH}/${item}" || true
    [ -e "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/${item}" ] && mv "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/${item}" .
  done
}

reconfigure_and_migrate() {
  install_gems

  kdk reconfigure
  
  bundle exec rake gitlab-db-migrate
  kdk stop
}

update_kdk() {
  kdk update
}

restart_kdk() {
  kdk stop
  kdk start
}

measure_time check_inotify
measure_time clone_gitlab
measure_time copy_items_from_bootstrap
measure_time reconfigure_and_migrate
measure_time update_kdk
measure_time restart_kdk

DURATION=$SECONDS
echo "Total Duration: $((DURATION / 60)) minutes and $((DURATION % 60)) seconds."
echo "Execution times for each function:"
cat "$LOG_FILE"
