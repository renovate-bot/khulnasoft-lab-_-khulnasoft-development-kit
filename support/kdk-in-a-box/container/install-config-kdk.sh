#!/usr/bin/env bash

set -euo pipefail

eval "$(~/.local/bin/mise activate bash)"

mise x -- kdk install khulnasoft_repo="https://khulnasoft.com/khulnasoft-community/khulnasoft-org/khulnasoft.git" telemetry_user="kdk-in-a-box"
mise x -- kdk config set hostname kdk.local
mise x -- kdk config set listen_address 0.0.0.0
mise x -- kdk config set webpack.enabled false
mise x -- kdk config set vite.enabled true
mise x -- kdk reconfigure
mise x -- kdk stop
