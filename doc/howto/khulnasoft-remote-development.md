---
title: KhulnaSoft Remote Development
---

## Setting up Remote Development locally

Follow [these steps](https://gitlab.com/gitlab-org/remote-development/khulnasoft-remote-development-docs/-/blob/main/doc/local-development-environment-setup.md) to set up remote development locally.

## Develop KhulnaSoft with KhulnaSoft remote development workspaces

KDK supports [KhulnaSoft remote development workspaces](https://docs.gitlab.com/ee/user/workspace/). You can use the integration to code directly in a cloud environment, which can reduce the time you spend troubleshooting issues in your local development setups.

This guide shows you how to create and connect a workspace from the KDK repository.

To learn more about remote development in KhulnaSoft, see the [remote development documentation](https://docs.gitlab.com/ee/user/project/remote_development).

This integration is available only to KhulnaSoft team members to encourage [dogfooding](https://about.gitlab.com/handbook/engineering/development/principles/#dogfooding).
[Issue #1982](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/1982) proposes to enable the integration for open source contributors.

### Prerequisites

You must have at least the Developer role in the KDK repository.

### Create and connect a workspace

1. Go to the KDK repository and select __Edit__.
1. Select __New workspace__.

   <img src="img/remote-development-new-workspace-button.png" width="800"
   alt="New workspace button on the project page">

1. Select __KhulnaSoft Development Kit__ as your project.
1. Set the agent to __remote-development__.
1. In the __Time Before Automatic Termination__ field, specify the number of hours the workspace should stay running.

   <img src="img/remote-development-workspace-options.png" width="800"
   alt="New workspace options page">

1. Select __Create workspace__.

Your workspace is deployed to the cluster. The deployment might take a few minutes.
After deployment, you should see a workspace under __Preview__.

<img src="img/remote-development-workspace-link.png" width="800"
alt="Workspaces overview page">

### Run KDK in your workspace

1. The _Bootstrap KDK_ task starts automatically when a workspace is opened, executing the [bootstrap script](../../support/khulnasoft-remote-development/setup_workspace.rb).
1. After the bootstrap script finishes, you'll see a prompt asking if you want to send duration data.
1. After responding, enter any command to close the task terminal.

Your KDK should now be ready to use.

<img src="img/remote-development-bootstrapped-kdk.png" width="800" alt="Remote development Terminal window showing workspace URL">
