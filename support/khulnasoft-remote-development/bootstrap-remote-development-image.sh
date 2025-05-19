#!/usr/bin/env bash

set -xeuo pipefail
IFS=$'\n\t'

clone_kdk() {
  echo "# --- Clone KDK ---"
  sudo mkdir -p "${WORKSPACE_DIR_NAME}/gitlab"
  sudo chown -R ${WORKSPACE_USER}:${WORKSPACE_USER} "${WORKSPACE_DIR_NAME}"
  cd "${WORKSPACE_DIR_NAME}"
  git clone https://github.com/khulnasoft-lab/khulnasoft-development-kit.git
}

configure_kdk() {
  echo "# --- Configure KDK ---"
  cd "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit"

  # Set remote origin URL if available
  if [[ -n "${GIT_REMOTE_ORIGIN_URL:-}" ]]; then
    git remote set-url origin "${GIT_REMOTE_ORIGIN_URL}.git"
    git fetch
  fi

  [[ -n "${GIT_CHECKOUT_BRANCH:-}" ]] && git checkout "${GIT_CHECKOUT_BRANCH}"

  make bootstrap

  # Set asdf dir correctly
  ASDF_DIR="${ASDF_DIR:-${HOME}/.asdf}"
  # shellcheck source=/workspace/.asdf/asdf.sh
  source "${ASDF_DIR}/asdf.sh"

  configure_rails
  configure_go_projects
  cat kdk.yml
}

configure_rails() {
  echo "# --- Configure Rails settings ---"
  # Disable bootsnap as it can cause temporary/cache files to remain, resulting
  # in Docker image creation to fail.
  kdk config set gitlab.rails.bootsnap false
  kdk config set gitlab.rails.port 443
  kdk config set gitlab.rails.https.enabled true
}

configure_go_projects() {
  echo "# --- Configure Go projects ---"
  kdk config set gitaly.skip_compile true
  kdk config set khulnasoft_shell.skip_compile true
  kdk config set workhorse.skip_compile true
}

install_kdk() {
  echo "# --- Install KDK ---"
  kdk install shallow_clone=true
  kdk stop || true
  KDK_KILL_CONFIRM=true kdk kill || true
  ps -ef || true
  mv gitlab/config/secrets.yml .
  rm -rf gitlab/ tmp/ || true
  git restore tmp
  sudo cp ./support/completions/kdk.bash "/etc/profile.d/90-kdk.sh"
  cd "${WORKSPACE_DIR_NAME}"

  # Set up a symlink in order to have our .tool-versions as defaults.
  # A symlink ensures that it'll work even after a kdk update.
  ln -s "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/.tool-versions" "${HOME}/.tool-versions"
}

set_permissions() {
  sudo chgrp -R 0 "${WORKSPACE_DIR_NAME}"
  sudo chmod -R g=u "${WORKSPACE_DIR_NAME}"
  sudo chmod g-w "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/postgresql/data"
}

cleanup() {
  echo "# --- Cleanup build caches ---"
  # Logged issue https://gitlab.com/gitlab-org/gitaly/-/issues/5459 to provide make
  # target in Gitaly to clean this up reliably
  sudo rm -rf "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/gitaly/_build/deps/libgit2/source"
  sudo rm -rf "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/gitaly/_build/cache"
  sudo rm -rf "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/gitaly/_build/deps"
  sudo rm -rf "${WORKSPACE_DIR_NAME}/khulnasoft-development-kit/gitaly/_build/intermediate"
  sudo rm -rf /tmp/*
}

clone_kdk
configure_kdk
install_kdk
set_permissions
cleanup
