---
title: Gitaly and Praefect
---

KhulnaSoft uses [Gitaly](https://docs.khulnasoft.com/ee/administration/gitaly/index.html) to abstract all
Git calls. To work on local changes to `gitaly`, please refer to the
[Beginner's guide to Gitaly contributions](https://khulnasoft.com/khulnasoft-org/gitaly/blob/master/doc/beginners_guide.md).

For more information on Praefect, refer to
[Gitaly Cluster](https://docs.khulnasoft.com/ee/administration/gitaly/praefect.html).

In KDK, you can change Gitaly and Praefect configuration in the following ways:

- Modify [Gitaly and Praefect options](#gitaly-and-praefect-options).
- [Add Gitaly nodes](#add-gitaly-nodes) to the `default` virtual storage.
- [Add virtual storages](#add-virtual-storages) served by additional Gitaly nodes.

See also [Automate different Praefect configurations](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/827)
for information about automating more of these processes.

## Feature flags

You can set Gitaly feature flags in two ways:

- Set the feature flags in KhulnaSoft Rails. These are passed to Gitaly as they would be in production. This way is recommended and you can
  read more in the [KhulnaSoft documentation](https://docs.khulnasoft.com/ee/development/feature_flags/). As
  [documented](https://khulnasoft.com/khulnasoft-org/gitaly/-/blob/master/doc/PROCESS.md#use-and-limitations), prepend the feature flag name
  with `gitaly_`.
- Enable all feature flags.

### Enable all feature flags

To enable all Gitaly feature flags:

1. Set the following in `kdk.yml`:

   ```yaml
   gitaly:
     enable_all_feature_flags: true
   ```

1. Run `kdk reconfigure`.

## Gitaly and Praefect options

By default, KDK is set up use Praefect as a proxy to Gitaly. To disable Praefect, set the following
in `kdk.yml`:

```yaml
praefect:
  enabled: false
```

For other KDK Gitaly and Praefect options, refer to the `gitaly:` and `praefect:` sections of the
[`kdk.example.yml`](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/master/kdk.example.yml).

## Add Gitaly nodes

By default, KDK generates Praefect configuration containing only one Gitaly node (`node_count: 1`).
To add additional backend Gitaly nodes to use on the `default` virtual storage:

1. Increase the number of nodes by increasing the `node_count` in `kdk.yml`. For example:

   ```yaml
   praefect:
     node_count: 2
   ```

1. Run `kdk reconfigure`.
1. Run `kdk restart`.

Two Gitaly nodes now start when KDK starts. KDK handles the required Praefect configuration for you.

## Add virtual storages

If you need to work with multiple [repository storages](https://docs.khulnasoft.com/ee/administration/repository_storage_types.html) in KhulnaSoft, you can create new virtual storages in
Praefect. You need at least [one more Gitaly node](#add-gitaly-nodes) or storage to create another
virtual storage.

1. Assuming one extra Gitaly node has been created, add a `virtual_storage` definition to
   `gitaly/praefect.config.toml`. For example if one extra Gitaly node was added, your
   configuration might look like:

   ```toml
   [[virtual_storage]]
   name = 'default'

   [[virtual_storage.node]]
   storage = "praefect-internal-0"
   address = "unix:/Users/paulokstad/khulnasoft-development-kit/gitaly-praefect-0.socket"

   [[virtual_storage]]
   name = 'default2'

   [[virtual_storage.node]]
   storage = "praefect-internal-1"
   address = "unix:/Users/paulokstad/khulnasoft-development-kit/gitaly-praefect-1.socket"
   ```

   This creates two virtual storages, each served by their own Gitaly node.

1. Edit `khulnasoft/config/khulnasoft.yml` to add the new virtual storage to KhulnaSoft. For example:

   - Before:

     ```yaml
     repositories:
       storages: # You must have at least a `default` storage path.
         default:
           path: /
           gitaly_address: unix:/Users/paulokstad/khulnasoft-development-kit/praefect.socket
     ```

   - After:

     ```yaml
     repositories:
       storages: # You must have at least a `default` storage path.
         default:
           path: /
           gitaly_address: unix:/Users/paulokstad/khulnasoft-development-kit/praefect.socket
         default2:
           path: /
           gitaly_address: unix:/Users/paulokstad/khulnasoft-development-kit/praefect.socket
     ```

1. Run `kdk restart`.

## Praefect on a Geo secondary

Praefect needs a read-write capable database to track its state. On a Geo
secondary the main database is read-only. So when KDK is
[configured to be a Geo secondary](geo/advanced_installation.md#secondary),
Praefect uses the Geo tracking database instead.

If you have modified this setting, you need to recreate the Praefect database
using:

```shell
kdk reconfigure
```

## Transactions

To run Gitaly with [transactions](https://docs.khulnasoft.com/ee/architecture/blueprints/gitaly_transaction_management/),
configure the following:

```yaml
gitaly:
  transactions:
    enabled: true
praefect:
  enabled: false
```

For more information on the implementation, see
[Gitaly merge request 6496](https://khulnasoft.com/khulnasoft-org/gitaly/-/merge_requests/6496).
