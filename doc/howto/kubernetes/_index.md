---
title: Use KDK with a GKE cluster
---

This document describes connecting KDK to a Kubernetes cluster created on
[Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine).

## Connect to your cluster

### Install gcloud and kubectl

Before you can run the spec, you need `gcloud` and `kubectl` installed.

Follow the instructions at <https://cloud.google.com/sdk/docs/quickstarts>
for the operating system that you are using to install `gcloud`.
Alternatively, if you are using Homebrew on MacOS, you can install
[`gcloud` via Homebrew Cask](https://formulae.brew.sh/cask/google-cloud-sdk):

```shell
brew install --cask google-cloud-sdk
```

> [!note]
> If you have installed `gcloud` via Homebrew Cask, as described
> above, you need to add the following lines in your profile
> to set the correct PATH to be able to run `gcloud` and the `kubectl` binary below.

```shell
# For bash users, add to ~/.bash_profile
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"

# For zsh users, add to ~/.zprofile
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
```

After you have installed `gcloud`, run the
[init](https://cloud.google.com/sdk/docs/quickstart-macos#initialize_the_sdk) step:

```shell
gcloud init
```

This init command helps you set up your default zone and project. It also prompts you to log in with
your Google account.

```plaintext
To continue, you must log in. Would you like to log in (Y/n)? Y
```

After you have logged in, select your default project and zone.
After you have logged in, select your default project and zone. Use one of the following GCP projects:

- `gitlab-internal-153318`: Use this project for general development and testing.
- `gitlab-qa-resources`: Use this project for composing and running the [Auto DevOps](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/qa/specs/features/browser_ui/7_configure/auto_devops) tests.

Next, install `kubectl` as a component of `gcloud` :

```shell
gcloud components install kubectl
```

Make sure to close and reopen your terminal after making these changes.

## Constraints

### Registry must be routable

Auto DevOps "deploys" your application to a K8s cluster but the way
this works in K8s is that the cluster actually needs to
download the image from your Docker registry running on your machine. Put
another way the K8s cluster needs access over HTTPS to the registry running
on your machine. And HTTPS is necessary as K8s does not download insecure images
by default.

### GKE K8s cluster is outside of your network

You likely want to run K8s clusters on GKE as this allows us to test our
GCP integrations as well. You can use minikube too but there are limitations
with this as minikube doesn't test our GCP integration and minikube does not
simulate a real cluster (eg. internet-facing load balancers with external IP
address are not possible). So when you do choose GKE you conclude that your
registry running on your machine needs to be internet accessible since GKE
is outside your network.

### Runner on K8s cluster is outside of your network

Assuming that you choose to run the K8s cluster on GKE you may also wish to use
the [1 click install](https://docs.gitlab.com/ee/user/project/clusters/#installing-applications)
to install the Runner on this cluster. This means that in addition to the
registry (which is a separate server on your machine), you also need the
KhulnaSoft instance to be internet accessible because now the runner is not on your
network.

### Test changes to `Auto-DevOps.gitlab-ci.yml` on KhulnaSoft.com

If you are only changing `Auto-DevOps.gitlab-ci.yml`, you are
able to just copy and paste this into a `.gitlab-ci.yml` on a project on
KhulnaSoft.com to test it out. This doesn't work if you're also testing this
with corresponding changes to code.

### Use some seed data for viewing stuff in the UI

At the moment we don't have anything seeded for Kubernetes integrations
or Auto DevOps projects. If we had some seeds for the following tables it
may help if you are only working on the frontend under some limited
circumstances:

- `clusters`
- `clusters_applications_helm`
- `clusters_applications_ingress`
- `clusters_applications_prometheus`
- `clusters_applications_runners`
- `clusters_applications_jupyter`

## Cleaning up unused GCP resources

When you create a new cluster in GCP for testing purposes it is usually a good
idea to clean up after yourself. Particularly during testing you may wish to
regularly create new test clusters with each test and as such you should be
making sure you delete your old cluster from GCP. You can find your clusters on
the [Kubernetes page](https://console.cloud.google.com/kubernetes/list) in GCP
console. If you see one of your clusters you are no longer using then simply
delete it from this page.

Unfortunately deleting a cluster is not enough to fully clean up after yourself
on GCP. When creating a cluster and installing Helm apps on that cluster you
actually end up creating other GCP resources that are not deleted when the
cluster is deleted. As such it is important to also periodically find and
delete these unused (orphaned) GCP resources. Please read on for how to do
that.

### Unused Load Balancers

When you install the Ingress on your cluster, it creates a GCP Load Balancer
behind the scenes with a static IP address. Because static IP addresses have a
fixed limit per GCP project and also because they cost money it is important
that we periodically clean up all the unused orphaned load balancers from
deleted clusters.

You can find and delete any unused load balancers following these steps:

1. Open
   [The Load Balancers page](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list?filter=%255B%257B_22k_22_3A_22Protocol_22_2C_22t_22_3A10_2C_22v_22_3A_22_5C_22TCP_5C_22_22%257D%255D)
   in the GCP console
1. Open every one of the TCP load balancers in new tabs
1. Check through every tab for the yellow warning next to the nodes list saying
   the nodes they point to no longer exist
1. Delete the load balancer if it has no green ticks and only yellow warnings
   about nodes no longer existing

### Unused Persistent Disks

When creating a new GKE cluster, it also provisions persistent disks in your
GCP project. Because persistent disks have a fixed limit per GCP project and
also because they cost money it is important that we periodically clean up all
the unused orphaned persistent disks from deleted clusters.

You can find and delete any unused persistent disks following these steps:

1. Open [Compute Engine Disks page](https://console.cloud.google.com/compute/disks?diskssize=200&disksquery=%255B%257B_22k_22_3A_22userNames_22_2C_22t_22_3A10_2C_22v_22_3A_22_5C_22%27%27_5C_22_22%257D%255D)
   in the GCP console
1. Be sure you are filtered by `In use by: ''` and you should also notice the
   `In use by` column is empty to verify they are not in use
1. Search this list for a `Name` that matches how you were naming your
   clusters. For example a cluster called `mycluster` would end up with
   persistent disks named `gke-mycluster-pvc-<random-suffix>`. If they match
   the name you are expecting and they are not in use it is safe to delete
   them.

> [!note]
> When running the integration tests, it creates clusters named
> `qa-cluster-<timestamp>-<random-suffix>`. As such it is
> actually safe and encouraged for you to also delete unused persistent disks
> created by these automated tests. The disk name starts with
> `gke-qa-cluster-`. Also note there can be many such disks here as our
> automated tests do not clean these up after each run. It is a good idea to
> clean them up yourself while you're on this page.

## Tips, Troubleshooting and Useful Commands

Be sure to check out:

- [Kubernetes - tips and troubleshooting](tips_and_troubleshooting.md)
- [Kubernetes - useful commands](useful_commands.md)

They might save you a lot of time during work.
