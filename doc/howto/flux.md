---
title: Flux CD
---

Installing and configuring [Flux CD](https://fluxcd.io/) locally allows you to test and develop [GitOps](https://docs.gitlab.com/ee/user/clusters/agent/gitops.html)-related features and integrations.

## Install dependencies

You need to be able to access a Kubernetes cluster locally using the `kubectl` command.

If you want to host a local Kubernetes cluster for development purposes,
you can use [Rancher Desktop](https://rancherdesktop.io/) or [k3d](https://k3d.io/v5.6.3/).

## Create a personal access token

To authenticate with the Flux CLI, create a personal access token with
the `api` scope:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access Tokens**.
1. Enter a name and optional expiry date for the token.
1. Select the `api` scope.
1. Select **Create personal access token**.

## Create a SSH key

Generate an SSH key for KDK access:

1. Run the command:

   ```shell
   ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/kdk
   ```

1. Copy the generated public key:

   ```shell
   cat ~/.ssh/kdk.pub | pbcopy
   ```

1. Register it for your user:

   1. On the left sidebar, select your avatar.
   1. Select **Edit profile**.
   1. On the left sidebar, select **SSH Keys > Add new key**.
   1. Add the copied public key.

## Create a project in your KDK

Create a project to hold the Flux configuration.
It can be an empty project within any group.
For example, you can create a project named `flux-config` in the `gitlab-org` group.

## Complete a bootstrap installation

Bootstrap Flux into an empty KhulnaSoft repository with the
[`flux bootstrap`](https://fluxcd.io/flux/installation/bootstrap/gitlab/) command.

Since you only need Flux for development purposes, you can use an SSH repository connection. This simplifies the local KDK setup, including avoiding an issue where Flux doesn't verify local certificates if KDK runs behind [NGINX](nginx.md).

To bootstrap flux, run this command:

```shell
flux bootstrap git \
  --url=<ssh link to git repository> \
  --branch=main \
  --private-key-file=<path to ssh key file> \
  --path=clusters/my-cluster
```

If using the example values from previous steps, your command should look like this:

```shell
 flux bootstrap git
  --url=ssh://git@kdk.test:2222/gitlab-org/flux-config.git \
  --branch=main \
  --private-key-file=/Users/username/.ssh/kdk \
  --path=clusters/test-cluster
```

### Set up the KAS integration

To fully replicate a GitOps configuration locally, you'll also need to create and register an `agentk`. 

First, make sure your KDK is [properly set up for KAS](kubernetes_agent.md).

Then follow the [Flux set up tutorial](https://docs.gitlab.com/ee/user/clusters/agent/gitops/flux_tutorial.html#register-agentk) with the following modification:
When installing the `agentk` with Flux, use the `grpc` address to connect to KAS. If you used the default  [loopback alias IP](local_network.md#create-loopback-interface) your YAML configuration should look like:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  labels:
    app.kubernetes.io/component: agentk
    app.kubernetes.io/created-by: gitlab
    app.kubernetes.io/name: agentk
    app.kubernetes.io/part-of: gitlab
  name: gitlab-agent
  namespace: gitlab
spec:
  interval: 1h0m0s
  url: https://charts.gitlab.io
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: gitlab-agent
  namespace: gitlab
spec:
  chart:
    spec:
      chart: gitlab-agent
      sourceRef:
        kind: HelmRepository
        name: gitlab-agent
        namespace: gitlab
  interval: 1h0m0s
  values:
    config:
      kasAddress: "grpc://172.16.123.1:8150"
      secretName: gitlab-agent-token
```

Once the agent is installed, you'll have a fully functional local GitOps solution you can use for development purposes.
