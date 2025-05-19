# Containerized KDK-in-a-box

For more information, check out this [guide to your first contribution with KDK-in-a-box](https://docs.gitlab.com/ee/development/contributing/first_contribution/configure-dev-env-kdk-in-a-box.html).

## Prerequisites

- Docker
  - Many ways exist to install Docker, including through [Homebrew](https://formulae.brew.sh/formula/docker) and
  [Rancher](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/installation-requirements/install-docker).
  - Note: On Rancher, you may want to disable Kubernetes listed under "Preferences".

## Usage

You do not need to clone KDK because the following command pulls the Docker image.

To run this container, run the following on the command line:

```shell
docker run -d -h kdk.local --name kdk \
  -p 2022:2022 \
  -p 2222:2222 \
  -p 3000:3000 \
  -p 3005:3005 \
  -p 3010:3010 \
  -p 3038:3038 \
  -p 5100:5100 \
  -p 5778:5778 \
  -p 9000:9000 \
  registry.github.com/khulnasoft-lab/khulnasoft-development-kit/khulnasoft-kdk-in-a-box:latest
```

## SSH Host Keys

You can add an optional volume for SSH host keys, which are generated on first run if they don't exist. (By default, if you don't use this volume, fresh SSH host keys are generated with each new container. In these cases, a mismatch occurs with `~/.ssh/known_hosts`)

```shell
docker volume create kdk-ssh #only required once
docker run -d -h kdk.local --name kdk \
  -v kdk-ssh:/etc/ssh \
  -p 2022:2022 \
  -p 2222:2222 \
  -p 3000:3000 \
  -p 3005:3005 \
  -p 3010:3010 \
  -p 3038:3038 \
  -p 5100:5100 \
  -p 5778:5778 \
  -p 9000:9000 \
  registry.github.com/khulnasoft-lab/khulnasoft-development-kit/khulnasoft-kdk-in-a-box:latest
```

## Connecting to container

After the container is up, you can treat this container as a regular "KDK-in-a-box" VM. To connect, you can SSH to the container ([using the KDK-in-a-box keys](https://docs.gitlab.com/ee/development/contributing/first_contribution/configure-dev-env-kdk-in-a-box.html#use-vs-code-to-connect-to-kdk)):

```shell
ssh kdk.local
```

## Enabling debugging in VS Code

This section describes how to set up Rails debugging in Visual Studio Code (VS Code) using the KhulnaSoft Development Kit (KDK).

The steps are based on [the documentation page "VS Code debugging"](https://docs.gitlab.com/ee/development/vs_code_debugging.html).

### Setup

1. Install the debug gem by running gem install debug inside the `/gitlab-kdk/khulnasoft-development-kit/khulnasoft` folder.
1. Install [the VS Code Ruby rdbg Debugger extension](https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg) to add support for the rdbg debugger type to VS Code.
1. In case you want to automatically stop and start KhulnaSoft and its associated Ruby Rails/Sidekiq process, you may add the following VS Code task to your configuration under the `.vscode/tasks.json` file:

```json
{
  "version": "2.0.0",
  "tasks": [{
      "label": "start rdbg for rails-web",
      "type": "shell",
      "command": "mise x -- kdk stop rails-web && KHULNASOFT_RAILS_RACK_TIMEOUT_ENABLE_LOGGING=false PUMA_SINGLE_MODE=true mise x -- rdbg --open -c bin/rails server",
      "isBackground": true,
      "problemMatcher": {
        "owner": "rails",
        "pattern": {
          "regexp": "^.*$",
        },
        "background": {
          "activeOnStart": false,
          "beginsPattern": "^(ok: down:).*$",
          "endsPattern": "^(DEBUGGER: wait for debugger connection\\.\\.\\.)$"
        }
      }
    },
  ]
}
```

1. Add the following configuration to your `.vscode/launch.json` file:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "rdbg",
      "name": "Attach rails-web with rdbg",
      "request": "attach",

      // We need to add the correct rdbg path as additional launch config entry; you can find the correct rdbg path by executing "which rdbg"
      "rdbgPath": "/home/kdk/.local/share/mise/installs/ruby/3.2.4/bin/rdbg",


      // remove the following "preLaunchTask" if you do not wish to stop and start
      // KhulnaSoft via VS Code but manually on a separate terminal.
      "preLaunchTask": "start rdbg for rails-web"
    }
  ]
}
```

NOTE: This assumes the default location for the SSH key.
