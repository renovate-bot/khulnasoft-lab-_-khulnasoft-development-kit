---
title: Install KDK on minikube
---

KDK can be deployed to minikube / Kubernetes.

Note that this setup is an experimental phase and [not officially supported](../../../README.md#installation).

You can't develop KhulnaSoft using this strategy yet.

See [issue about](https://github.com/khulnasoft-lab/khulnasoft-development-kit/issues/243) for more details.

## How to use it?

1. [Install minikube](https://minikube.sigs.k8s.io/docs/start/)
1. Clone KDK repository
1. Start minikube using `minikube start`
1. Create pod using `kubectl create -f kdkube.yml`
1. See starting pod using `kubectl get pods`
1. Wait until KDK starts, see a progress in logs `kubectl logs -f kdk-[pod-id]`
1. Get the URL to KDK by typing `minikube service kdk --url`
1. Open KDK in the browser
