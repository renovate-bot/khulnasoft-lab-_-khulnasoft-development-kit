---
title: Accessing Prometheus via external services
---

Prerequisites:

- An existing KhulnaSoft-managed cluster with Prometheus installed.
- At least one deployment running on the cluster.

## Exposing the Prometheus endpoint for a KhulnaSoft-managed cluster

The following instructions are for [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine). If you
are using a local cluster such as minikube, you only need to find the external IP address and port of the Prometheus
service.

1. Log in to the cluster management page in GKE. For the Monitor stage, this is the [monitoring-development cluster](https://console.cloud.google.com/kubernetes/list?project=monitoring-development-241420).
1. Navigate to **Services & Ingress**.
1. Filter for `Name:prometheus-prometheus-server`, find the instance for your cluster, and click to open it.
1. Scroll down to **Ports** and copy the **Target Port**.
1. Open the deployment under **Deployments**.
1. Under the **Actions** dropdown, select **Expose**.
   - **Port**: Select a port. For example, 60000.
   - **Target Port**: Select the Target Port found in Step 4, e.g. 9090.
   - **Protocol**: Leave as-is (e.g. TCP).
   - **Service Type**: Load balancer.
1. Click **Save**. The UI opens a page for the load balancer service. The external
   IP address and port are visible under the **External endpoints** field.

   > [!note]
   > It may take several minutes for the load balancer to become operational.

Once complete, you may access the Prometheus server at the IP address and port shown.
You can test this by accessing the `/graph` endpoint. The Prometheus UI should be
visible there. That is, at `http://<IP address>:<port>/graph`.

Reference documentation:

- [Creating a Service of Type LoadBalancer](https://cloud.google.com/kubernetes-engine/docs/how-to/exposing-apps#creating_a_service_of_type_loadbalancer)
- [Prometheus Expression Browser](https://prometheus.io/docs/visualization/browser/)

## Connecting Grafana to a KhulnaSoft-managed Prometheus instance

1. Get a Grafana instance. _Note: The Grafana instance must be network-accessible from the KDK, and your Prometheus must be network-accessible from the Grafana instance._
   1. Create a local instance. Either:
      - Run `docker run -d -p 4000:3000 grafana/grafana` to spin up a local Grafana instance (default username/password: `admin`/`admin`).
      - Install a local version by:
        1. [Configuring the `grafana` service](../../configuration.md#grafana-settings) in `kdk.yml`:

            ```yaml
            grafana:
               enabled: true
            ```

        1. Running `kdk reconfigure` from the KDK root directory.
   1. Create a cloud instance, ensuring that visibility is set to 'public'. See [instructions](#configuring-a-hosted-grafana-instance).
1. Add a DataSource of type **Prometheus**.
1. In the URL field, add `http://<ip>:<port>` as detailed in
   [Exposing the Prometheus endpoint for a KhulnaSoft-managed cluster](#exposing-the-prometheus-endpoint-for-a-khulnasoft-managed-cluster).
1. Click **Save**.
1. Create a dashboard using Prometheus metrics. Refer to the following screenshot:

   ![Sample Grafana panel; query 'up'; legend '{{job}}'](../img/sample_grafana_panel.png)

## How to connect Grafana to KhulnaSoft

Refer to the documentation on [Embedding Grafana charts](https://docs.khulnasoft.com/ee/operations/metrics/embed_grafana.html#embedding-grafana-charts-core)
for details on configuring KhulnaSoft to integrate with Grafana.

## Configuring a hosted Grafana instance

1. Navigate to the [Grafana landing page](https://grafana.com/).
1. Click **Login** in the upper right hand corner.
1. Click **Sign Up Now** to sign up for a new account or enter your credentials if you already have an account.
1. Click **My Grafana** in the upper right.
1. Under **Hosted Grafana**, follow the flow to create a new instance.
1. When returning to this page again, click **Log In** under **Hosted Grafana** to access the Grafana instance.
