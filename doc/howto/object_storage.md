---
title: Object Storage (LFS, Artifacts, etc)
---

KhulnaSoft has Object Storage integration.
In this document we explain how to set this up in your development
environment.

Prerequisites:

- To use the KDK integration, you must install [MinIO](https://docs.minio.io/docs/minio-quickstart-guide) binary (no Docker image).
- To use the [MinIO console](https://github.com/minio/console), you must have at least [version `2021-07-08T01-15-01Z`](https://github.com/minio/minio/releases/tag/RELEASE.2021-07-08T01-15-01Z).
  If you use `mise` to manage MinIO, this dependency is managed for you.

You can enable the object store by adding the following to your `kdk.yml`:

```yaml
object_store:
  enabled: true
  port: 9000
```

The object store has the following default settings:

| Setting                | Default            | Description                                                                             |
|----------------------- |--------------------|-----------------------------------------------------------------------------------------|
| `enabled`              | `false`            | Enable or disable MinIO.                                                                |
| `port`                 | `9000`             | Port to bind MinIO.                                                                     |
| `console_port`         | `9002`             | Port to bind [MinIO Console](https://github.com/minio/console).                         |
| `access key`           | `minio`            | Access key needed by MinIO to log in via its web UI. Cannot be changed.                 |
| `secret key`           | `kdk-minio`        | Secret key needed by MinIO to log in via its web UI. Cannot be changed.                 |

Changing settings requires `kdk reconfigure` to be run.

## Backups

To set the object storage config for backups, configure the bucket in `object_store.backup_remote_directory`, for example:

```yaml
object_store:
  enabled: false
  backup_remote_directory: 'backups'
```

## MinIO errors

If you cannot start MinIO, you may have an old version not supporting the `--compat` parameter.

`kdk tail minio` shows a crash loop with the following error:

```plaintext
Incorrect Usage: flag provided but not defined: -compat
```

Upgrading MinIO to the latest version fixes it.

## Creating a new bucket

In order to start using MinIO from your KhulnaSoft instance you have to create buckets first.
You can create a new bucket by accessing <http://127.0.0.1:9000/> (default configuration).
