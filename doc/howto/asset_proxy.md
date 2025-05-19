---
title: Asset Proxy / Camo Server
---

KhulnaSoft can be configured to use an [asset proxy server](https://docs.khulnasoft.com/ee/security/asset_proxy).

## Local Installation

We currently recommend using [cactus/go-camo](https://github.com/cactus/go-camo#how-it-works) as it supports proxying video and is more configurable.

1. Follow the build and installation instructions at
   [building cactus/go-camo](https://github.com/cactus/go-camo#building). To check it's
   working, run the following from the `go-camo` directory:
   `go-camo` directory, you should be able to

   ```shell
   cd build/bin
   ./go-camo -k "somekey" --allow-content-video -H "Content-Security-Policy: media-src 'self'"
   ```

   `go-camo` returns something like:

   ```shell
   time="2019-07-24T14:31:29.988355000-05:00" level="I" msg="Starting server on: 0.0.0.0:8080"
   ```

1. Make sure your instance of KhulnaSoft is running, and that you have a private API token created.
   Then issue this from the command line, changing the values as needed:

    ```shell
    curl --request "PUT" "http://localhost:3000/api/v4/application/settings?\
    asset_proxy_enabled=true&\
    asset_proxy_url=http://localhost:8080&\
    asset_proxy_secret_key=<somekey>" \
    --header 'PRIVATE-TOKEN: <my-private-token>'
    ```

1. Restart the server for the changes to take effect. Each time you change
   any values for the asset proxy, you need to restart the server.
