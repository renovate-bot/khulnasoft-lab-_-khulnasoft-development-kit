#!/usr/bin/env bash

set -xeuo pipefail
IFS=$'\n\t'

install_prereqs() {
  apt-get update && apt-get upgrade -y
  apt-get install -y git sudo software-properties-common make curl locales bash-completion
  sed -i "s|# en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|" /etc/locale.gen
  sed -i "s|# C.UTF-8 UTF-8|C.UTF-8 UTF-8|" /etc/locale.gen
  locale-gen C.UTF-8 en_US.UTF-8
  {
    echo "export ASDF_DIR=${ASDF_DIR}"
    echo "export ASDF_DATA_DIR=${ASDF_DATA_DIR}"
    echo "source ${ASDF_DIR}/asdf.sh"
  } >> /etc/bash.bashrc

}

install_runner() {
  # --- Install KhulnaSoft Runner
  # KDK doesn't install it, but it is needed for running pipelines
  # https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/doc/howto/runner.md
  curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
  apt-get install gitlab-runner -y
}

configure_user() {
  useradd -l -u 5001 -G sudo -m -d "/home/${WORKSPACE_USER}" -s /bin/bash "${WORKSPACE_USER}"
  passwd -d "${WORKSPACE_USER}"
  echo "${WORKSPACE_USER} ALL=(ALL:ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${WORKSPACE_USER}_sudoers"
  mkdir -p "/home/${WORKSPACE_USER}"
  chgrp -R 0 /home
  chmod -R g=u /etc/passwd /etc/group /home
}

cleanup() {
  echo "# --- Cleanup apt caches ---"
  sudo apt-get clean -y
  sudo apt-get autoremove -y
  sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/*
}

install_prereqs
install_runner
configure_user
cleanup
