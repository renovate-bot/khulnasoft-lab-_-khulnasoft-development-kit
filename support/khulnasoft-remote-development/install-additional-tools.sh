#!/usr/bin/env bash

set -xeuo pipefail
IFS=$'\n\t'

setup_ssh() {
  # Install sshd
  apt-get update
  apt-get upgrade -y
  apt-get install -y openssh-server

  # Permit empty passwords
  sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth
  echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config

  # Create privilege separation directory
  mkdir /run/sshd

  # Create host keys and set permissions
  ssh-keygen -A
  chmod 775 /etc/ssh/ssh_host_rsa_key
  chmod 775 /etc/ssh/ssh_host_ecdsa_key
  chmod 775 /etc/ssh/ssh_host_ed25519_key

  # Give access to /etc/shadow for login
  chmod 775 /etc/shadow
}

setup_ssh
