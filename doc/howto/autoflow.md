---
title: AutoFlow (experimental)
---

The following sections document how to set up AutoFlow in KDK.

AutoFlow is experimental and may break at any time.

## Enable AutoFlow in KAS

To use AutoFlow with the KDK, you must configure the agent server for Kubernetes (KAS) to turn it on:

```yaml
khulnasoft_k8s_agent:
  autoflow:
    enabled: true
```

AutoFlow requires access to a running
[Temporal](https://temporal.io) server.
You may use the `./support/temporal` script to automatically
install and start a Temporal development server.

## Enable AutoFlow in Rails

To enable AutoFlow in Rails, an administrator can enable the `autoflow_enabled`
feature flag. AutoFlow support is scoped to projects.

## Configure Temporal client

The Temporal client is configured to connect to the
default `host_port` and `namespace` of the Temporal development server
(the development server started by the `./support/temporal` script).

You can reconfigure the Temporal client with the following configuration:

```yaml
khulnasoft_k8s_agent:
  autoflow:
    enabled: true

    # Configure for Temporal Cloud
    temporal:
      host_port: <namespace-name>.<namespace-id>.tmprl.cloud:7233
      namespace: <namespace-name>
      enable_tls: true
      certificate_file: /kdk/dir/temporal-client.pem
      key_file: /kdk/dir/temporal-client.key
```

### Set up Temporal Workflow data encryption, Codec Server, and Temporal Cloud

Configure KDK to support Temporal Workflow data encryption when using Temporal Cloud and the AutoFlow Codec Server for KDK.

Prerequisites:

- KDK setup with [NGINX](nginx.md)
- KDK setup with [HTTPS](nginx.md#update-kdkyml-for-https-optional)

To turn on `workflow_data_encryption`, add the following configuration:

```yaml
khulnasoft_k8s_agent:
  autoflow:
    enabled: true

    temporal:
      # ... setup settings come here (see above)
      workflow_data_encryption:
        enabled: true
```

To use the AutoFlow Codec Server with the Temporal Web UI, you must authorize a Temporal Cloud user to access the Codec Server.

You can extend the snippet with the `authorized_user_emails` setting:

```yaml
khulnasoft_k8s_agent:
  autoflow:
    enabled: true

    temporal:
      # ... setup settings come here (see above)
      workflow_data_encryption:
        enabled: true
        codec_server:
          authorized_user_emails:
            - <your-email@example.com>
```

Replace `your-email@example.com` with the email you used to sign in to Temporal Cloud.

Configure the Temporal Web UI to access the AutoFlow Codec Server for KDK. In the Temporal Web UI:

- Enter your `codec server endpoint`. For example, `https://kdk.test:3443/-/autoflow/codec/server` (Make sure that the host and port matches your setup).
- Turn on `Pass the user access token`.
- Turn on `Include cross-origin credentials`.

For more information about configuring the Temporal Web UI and Codec Server, see [Codec Server - Temporal Platform feature guide](https://docs.temporal.io/production-deployment/data-encryption).
