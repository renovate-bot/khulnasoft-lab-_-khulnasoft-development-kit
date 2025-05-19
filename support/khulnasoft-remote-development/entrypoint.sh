#!/usr/bin/env bash

set -xeuo pipefail
IFS=$'\n\t'

# Start sshd in the background
sudo /usr/sbin/sshd &

# Run bash in the foreground
exec "/bin/bash"
