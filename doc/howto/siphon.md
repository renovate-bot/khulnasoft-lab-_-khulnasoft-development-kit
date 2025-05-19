---
title: Configure Siphon to run in KDK
---

You can configure Siphon to run in KDK. **Siphon is not yet ready for production use.**

Siphon facilitates data synchronization between PostgreSQL and other data stores.
You can use Siphon in KDK to synchronize data between tables in PostgreSQL to matching tables in ClickHouse,
which allows you to write features that will benefit from the performance improvements of using an OLAP database.

## Prerequisites

Before configuring Siphon to run in KDK, you must:

- Enable ClickHouse in your KDK. For more information, see
  [ClickHouse within KhulnaSoft](https://docs.khulnasoft.com/ee/development/database/clickhouse/clickhouse_within_khulnasoft.html).
- Enable NATS in your KDK. `kdk config set nats.enabled true`
- Configure a Docker runtime. Only Docker Desktop is supported, but other container runtimes might work.

## Enable logical replication in PostgreSQL

To use Siphon, you must enable logical replication for KDK's main PostgreSQL database:

1. Open the `$KDK_ROOT/postgresql/data/postgresql.conf` file.
1. Change `wal_level` value to `wal_level = logical`.
1. If `$KDK_ROOT/postgresql/data/replication.conf` exists, also change `wal_level = logical` there. (This file is only likely to exist if PostgreSQL had replication enabled at any point)
1. Restart the PostgreSQL service:

   ```shell
   kdk restart postgresql
   ```

## Start and configure Siphon

To start and configure Siphon:

1. Update `kdk.yml` to enable Siphon:

   ```shell
   kdk config set siphon.enabled true
   ```

1. Run `kdk reconfigure` to generate configuration files.
1. Optional. In KhulnaSoft Rails directory (`khulnasoft`), run the Siphon migration generator to generate a table. The migration generator creates a migration to create a table
   in ClickHouse.

   ```shell
   rails generate khulnasoft:click_house:siphon users
   ```

1. Run the ClickHouse migrations:

   ```shell
   bundle exec rake khulnasoft:clickhouse:migrate
   ```

1. Run `kdk start` to start the new service.

## Validate

To validate that Siphon is working in your KDK:

1. Check that KDK is running the `siphon-producer-main-db` and `siphon-clickhouse-consumer` services.
1. Inspect the output of these services with `kdk tail siphon-producer-main-db` and `kdk tail siphon-clickhouse-consumer`.
1. Add new data to the provisioned tables (`users` in this case).
1. Note that the data should be replicated to the `siphon_users` table in ClickHouse. Validate this using:

   ```sql
   SELECT COUNT(*) FROM siphon_users FINAL;
   ```
