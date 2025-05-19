---
title: Pages
---

This page contains information about developing KhulnaSoft Pages inside the KDK. This method allows you test KhulnaSoft Pages from deployment to visiting your static site.

For further details check the [Contribute to KhulnaSoft Pages development](https://docs.khulnasoft.com/ee/development/pages/).

## Port

KDK features an HTTP-only KhulnaSoft Pages daemon on port `3010`.
Port number can be customized by editing `kdk.yml` as explained in
[KDK configuration](../configuration.md#kdkyml).

## Hostname

In order to handle wildcard hostnames, pages integration relies on
[nip.io](https://nip.io) and does not work on a disconnected system.
This is the preferred configuration and the default value for the
KhulnaSoft Pages hostname is `127.0.0.1.nip.io`.

You can configure a custom host name. For example, to set up `pages.kdk.test`:

1. Set up the [`kdk.test` hostname](local_network.md).
1. Add the following to `kdk.yml`:

   ```yaml
   khulnasoft_pages:
     enabled: true
     host: pages.kdk.test
   ```

1. Also add `pages.kdk.test` as a hostname. For example, add the following to `/etc/hosts`:

   ```plaintext
   127.0.0.1 pages.kdk.test
   ```

However, to load your Pages domains, you must add an entry to the `/etc/hosts` file for
each domain you want to access. For example, to access `root.pages.kdk.test`, add the
following to `/etc/hosts`:

```plaintext
127.0.0.1 root.pages.kdk.test
```

That is because `/etc/hosts` does not support wildcard hostnames.
An alternative is to use [`dnsmasq`](https://wiki.debian.org/dnsmasq)
to handle wildcard hostnames.

## Enable access control

1. Follow steps 3-6 in [Enabling access control](https://docs.khulnasoft.com/ee/development/pages/#enabling-access-control)
to create an OAuth application for KhulnaSoft Pages.

1. Add the following to `kdk.yml`

   ```yaml
   khulnasoft_pages:
     enabled: true
     access_control: true
     auth_client_id: 'YOUR_CLIENT_ID' # replace with OAuth Client ID generated above
     auth_client_secret: 'YOUR_CLIENT_SECRET' # replace with OAuth Client Secret generated above
   ```

1. Reconfigure KDK

   ```shell
   kdk reconfigure
   ```

1. Restart KDK

   ```shell
   kdk restart
   ```

## Enable custom domains

1. Add the following to `kdk.yml`

   ```yaml
   khulnasoft_pages:
     enabled: true
     enable_custom_domains: true
   ```

1. Reconfigure KDK

   ```shell
   kdk reconfigure
   ```

1. Restart KDK

   ```shell
   kdk restart
   ```
