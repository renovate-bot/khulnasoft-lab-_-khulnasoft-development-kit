#!/usr/bin/bash

gen_ssh_host_key() {
  cipher=$1

  if [ -f "/etc/ssh/ssh_host_${cipher}_key" ]; then
    echo "Key for ${cipher} already exists"
    return
  else
    echo "Creating key for ${cipher}"
    sudo ssh-keygen -q -f "/etc/ssh/ssh_host_${cipher}_key" -N '' -t "${cipher}"
    ssh-keygen -l -f "/etc/ssh/ssh_host_${cipher}_key.pub"
  fi
}

if [ ! -f /etc/ssh/sshd_config ]; then
  sudo cp -fr /etc/ssh-bootstrap/* /etc/ssh/
  for key in rsa dsa ecdsa ed25519; do
    gen_ssh_host_key $key
  done
fi

if ! grep -q 2022 /etc/ssh/sshd_config; then
  echo "Adding port 2022 to sshd_config"
  echo "Port 2022" | sudo tee -a /etc/ssh/sshd_config > /dev/null
fi

sudo /usr/sbin/sshd

cd /khulnasoft-kdk/khulnasoft-development-kit

eval "$(~/.local/bin/mise activate bash)"

mise x -- kdk restart

sleep 720d
