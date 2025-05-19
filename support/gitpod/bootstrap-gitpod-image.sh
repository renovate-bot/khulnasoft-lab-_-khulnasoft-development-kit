#!/usr/bin/env bash

set -xeuo pipefail
IFS=$'\n\t'

clone_kdk() {
  echo "# --- Clone KDK ---"
  sudo mkdir -p /workspace/khulnasoft
  sudo chown -R gitpod:gitpod /workspace
  cd /workspace
  git clone https://github.com/khulnasoft-lab/khulnasoft-development-kit.git
}

configure_kdk() {
  echo "# --- Configure KDK ---"
  cd /workspace/khulnasoft-development-kit

  # Set remote origin URL if available
  if [[ -n "${GIT_REMOTE_ORIGIN_URL:-}" ]]; then
    git remote set-url origin "${GIT_REMOTE_ORIGIN_URL}.git"
    git fetch
  fi

  [[ -n "${GIT_CHECKOUT_BRANCH:-}" ]] && git checkout "${GIT_CHECKOUT_BRANCH}"

  make bootstrap

  # Set asdf dir correctly
  ASDF_DIR="${ASDF_DIR:-${HOME}/.asdf}"
  source "${ASDF_DIR}/asdf.sh"

  configure_rails
  configure_webpack
  configure_telemetry_platform
  cat kdk.yml
}

configure_rails() {
  echo "# --- Configure Rails settings ---"
  # Disable bootsnap as it can cause temporary/cache files to remain, resulting
  # in Docker image creation to fail.
  kdk config set khulnasoft.rails.bootsnap false
  kdk config set khulnasoft.rails.port 443
  kdk config set khulnasoft.rails.https.enabled true
}

configure_webpack() {
  echo "# --- Configure Webpack settings ---"
  kdk config set webpack.host 127.0.0.1
  kdk config set webpack.live_reload false
  kdk config set webpack.sourcemaps false
}

configure_telemetry_platform() {
  kdk config set telemetry.environment 'gitpod'
}

configure_telemetry() {
  echo "# --- Configure Telemetry settings ---"
  cd "$HOME/khulnasoft-development-kit"
  kdk telemetry
}

install_kdk() {
  echo "# --- Install KDK ---"
  kdk install
  kdk stop || true
  KDK_KILL_CONFIRM=true kdk kill || true
  ps -ef || true
  mv khulnasoft/config/secrets.yml .
  rm -rf khulnasoft/ tmp/ || true
  git restore tmp
  cp ./support/completions/kdk.bash "$HOME/.bashrc.d/90-kdk"
  cd /workspace
  mv khulnasoft-development-kit "$HOME/"

  # Set up a symlink in order to have our .tool-versions as defaults.
  # A symlink ensures that it'll work even after a kdk update.
  ln -s /workspace/khulnasoft-development-kit/.tool-versions "$HOME/.tool-versions"
}

cleanup() {
  echo "# --- Cleanup apt caches ---"
  sudo apt-get clean -y
  sudo apt-get autoremove -y
  sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/*

  echo "# --- Cleanup build caches ---"
  sudo rm -rf "$HOME/khulnasoft-development-kit/gitaly/_build/deps/git/source"
  sudo rm -rf "$HOME/khulnasoft-development-kit/gitaly/_build/deps/libgit2/source"
  sudo rm -rf "$HOME/khulnasoft-development-kit/gitaly/_build/cache"
  sudo rm -rf "$HOME/khulnasoft-development-kit/gitaly/_build/deps"
  sudo rm -rf "$HOME/khulnasoft-development-kit/gitaly/_build/intermediate"
  sudo rm -rf "$HOME/.cache/"
  sudo rm -rf /tmp/*

  # Cleanup temporary build folder
  sudo rm -rf /workspace
}

clone_kdk
configure_kdk
install_kdk
cleanup
configure_telemetry