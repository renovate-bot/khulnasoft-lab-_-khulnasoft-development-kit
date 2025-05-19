---
title: Running in K3d
---

## Prerequisite(s)

- [Install K3d](https://github.com/rancher/k3d#get)

## Run the end-to-end test

[K3d](https://github.com/rancher/k3d) is a "Little helper to run Rancher Lab's k3s in Docker."

Instead of using a third-party provider such as GCP, we can have a fully-functional Kubernetes cluster running
on the machine under test.

Execute the following command in the `qa/` directory:

```shell
KHULNASOFT_ADMIN_ACCESS_TOKEN=<admin-access-token> bundle exec bin/qa Test::Integration::Kubernetes https://localhost:3001 -- qa/specs/features/browser_ui/7_configure/kubernetes/kubernetes_integration_spec.rb
```

### Notes

`KHULNASOFT_ADMIN_ACCESS_TOKEN` is required and should be generated before the start of the test.
This token allows our test to set application settings which is required for KhulnaSoft to connect to a local k3d server.

The end-to-end test(s) require a clean k3d installation with no clusters running. Ensure all running
clusters are torn down before running any tests.
