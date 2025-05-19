---
title: Docker Registry replication
---

## How it works

On every push of new Docker image, KhulnaSoft creates a special Geo event that is
propagated to secondary nodes. On the secondary node, there is a specialized
worker called `Geo::ContainerRepositoryServiceWorker` that fetches the
image from primary node.

## How to set up

Docker Registry replication can be configured in KDK.

Follow steps below to enable it on your local machine. These instructions assume
you have two Geo nodes (a primary and a secondary) on your local machine. If not, follow the
[KhulnaSoft Geo](geo.md) instructions to set them up.

### Enable Docker Registry on both nodes

To enable Docker Registry on both nodes:

1. Follow the instructions for [Docker Registry](registry.md) on both nodes.
1. Ensure the registry service port used on the secondary is different to the port used
   on the primary by [changing one of the port numbers](registry.md).

### Enable notification on primary's Registry

Add the following lines to `registry/config.yml` of your primary node:

```yaml
notifications:
  endpoints:
    - name: geo_event
      url: http://host.docker.internal:3001/api/v4/container_registry_event/events
      headers:
        Authorization: [<secret>]
      timeout: 500ms
      threshold: 5
      backoff: 1s
```

In this example:

- `secret` is a secret word used for communication between Registry and the primary node.
- The primary node is running on port `3001` of your localhost.

### Configure the primary node

Add the secret from the Registry configuration above to `config/gitlab.yml`:

```yaml
registry:
  notification_secret: <secret>
```

### Configure the secondary node

Enable registry replication on secondary node in your `kdk.yml`:

```yaml
geo:
  registry_replication:
    enabled: true
    primary_api_url: http://localhost:5100 # internal address to the primary registry, will be used by KhulnaSoft to directly communicate with primary registry API
```

### Install certificates on the secondary node

Copy `localhost.crt` and `localhost.key` from your primary node to
the secondary node.

### Restart

Please restart both nodes.
