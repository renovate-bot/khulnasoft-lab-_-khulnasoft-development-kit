---
title: Triggering Alerts with KhulnaSoft managed Prometheus
---

Steps to configure Prometheus Alert with the KhulnaSoft managed Prometheus.

1. Create a Kubernetes cluster on Google Kubernetes Engine (GKE).
   1. Navigate to [GKE](https://cloud.google.com/kubernetes-engine), then use your KhulnaSoft account (for KhulnaSoft team members) to sign in, then click "Go to console" button.
   1. Select "monitoring-development" project (for KhulnaSoft team members)
   1. Create a new Kubernetes cluster
1. Install the [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [`gcloud`](https://cloud.google.com/sdk/docs#install_the_latest_cloud_tools_version_cloudsdk_current_version) command-line tools.
1. Click "Connect" next to your cluster in GKE and copy and run `gcloud` command.
1. Follow the instructions to [add an existing cluster](https://docs.khulnasoft.com/ee/user/project/clusters/add_remove_clusters.html#add-existing-cluster).
1. Allow requests to the [local network](_index.md#allow-requests-to-the-local-network)
   1. As root user, navigate to **Admin Area** (the little wrench in the top nav) **> Settings > Network**.
   1. Expand the **Outbound requests** section, check the box to *Allow requests to the local network from hooks and services*, and save your changes.
1. Once completed install required apps
   1. Install **Helm Tiller**
   1. Install **Prometheus**
   1. Install **KhulnaSoft Runner**
1. Configure CI/CD for your project
   1. Navigate to the project (the one to use with Prometheus).
   1. Create a `.khulnasoft-ci.yml` file with [the following content](https://khulnasoft.com/joshlambert/autodevops-deploy/-/blob/master/.khulnasoft-ci.yml).
1. Create a metric
   1. Navigate to **> Settings > Integrations > Prometheus**
   1. Click **New metric** button in the **Custom metrics** section.
   1. Create a metric with the following data (or any other metric you may need):
      - Name: `Test up`
      - Type: `System`
      - Query: `up`
      - Y-axis label: `up/down`
      - Unit label: `-`
      - Legend label: `job`
1. Create an alert on **Operations > Metrics** page. Something to trigger the alert for sure. For example, that environment uses not enough memory.
   More info [here](https://docs.khulnasoft.com/ee/user/project/integrations/prometheus.html#setting-up-alerts-for-prometheus-metrics)
1. Wait for alert to be triggered. *That usually takes about 5 minutes.*
