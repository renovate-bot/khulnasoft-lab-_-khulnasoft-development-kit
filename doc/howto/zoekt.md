---
title: Zoekt
---

KhulnaSoft Enterprise Edition has a [Zoekt](https://github.com/sourcegraph/zoekt)
integration, which you can enable in your development environment.

## Installation

### Enable Zoekt in the KDK

The KhulnaSoft Zoekt component is automatically downloaded into your KDK root under `/khulnasoft-zoekt-indexer`.

To enable the service and run it as part of `kdk start`:

1. Run `kdk config set zoekt.enabled true`.
1. Run `kdk reconfigure`.
1. Run `kdk start`.
   This starts six Zoekt servers:
   - `khulnasoft-zoekt-indexer` for test.
   - `khulnasoft-zoekt-indexer-1` for development.
   - `khulnasoft-zoekt-indexer-2` for development.
   - `khulnasoft-zoekt-webserver` for test.
   - `khulnasoft-zoekt-webserver-1` for development.
   - `khulnasoft-zoekt-webserver-2` for development.

### Configure Zoekt in development

In order to enable Zoekt for the entire instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Exact code search configuration**.
1. Select the **Enable indexing**,  **Enable searching**, and **Index root namespaces automatically** checkboxes.
1. Select **Save changes**.

You can monitor the indexing progress via `bin/rails "gitlab:zoekt:info[10]"`. When you see that replicas and indices are ready, you can perform the searches.

Now, if you create a new public project in any of the namespaces (for example, `flightjs`) or update
any existing public project, it is indexed in Zoekt. Code searches within these projects are served by Zoekt.

Group-level searches are also served by Zoekt.

### Switch to a different version of KhulnaSoft Zoekt

The default KhulnaSoft Zoekt Indexer version is defined in [`lib/kdk/config.rb`](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/lib/kdk/config.rb).

To change this, set `indexer_version`:

```shell
   kdk config set zoekt.indexer_version v1.2.3
```

`indexer_version` is any valid ref that can be checked out.

### Test changes to Zoekt setup instructions without changing the development environment

To configure Zoekt in an environment without changing any of the settings
for your current environment, use [KDK-in-a-box](https://docs.gitlab.com/development/contributing/first_contribution/configure-dev-env-kdk-in-a-box/).

Before testing this, you must [configure a developer license in your KDK](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/tree/main/doc?ref_type=heads#configure-developer-license-in-kdk).

## Troubleshooting

### No preset version installed for command go

If you get this error during installation, execute the provided command
to install the correct version of Go:

```plaintext
No preset version installed for command go
Please install a version by running one of the following:
```

We cannot use the same Go version we use for other tools because the supported
version is controlled by Zoekt.
