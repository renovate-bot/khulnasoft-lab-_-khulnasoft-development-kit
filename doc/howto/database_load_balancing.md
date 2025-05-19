---
title: Database load balancing
---

This document describes the required steps to enable and test the [database load balancing](https://docs.khulnasoft.com/administration/postgresql/database_load_balancing/) feature in KDK.

To also test service discovery for database replicas, see the [database load balancing with service discovery documentation](database_load_balancing_with_service_discovery.md).

## Assumptions

For these instructions, we assume that you are running all commands from the KDK root.

## Configure KDK

1. Edit `kdk.yml`:

   ```yaml
   postgresql:
     replica:
       enabled: true
   load_balancing:
     enabled: true
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

1. Restart KDK:

   ```shell
   kdk restart
   ```

At this point you should see both a `postgresql` and a `postgresql-replica` service entry in the `kdk restart` output:

```plaintext
ok: run: ./services/postgresql: (pid 81204) 1s, normally down
ok: run: ./services/postgresql-replica: (pid 81202) 1s, normally down
```

Any data created in KhulnaSoft should now be replicated to the secondary database in realtime, and most `SELECT` queries should be routed to the secondary.

## Validate

Now that the databases were prepared for replication, we should validate whether the applied configurations produced the desired effect.

### Primary

1. Open a `psql` console:

   ```shell
   kdk psql
   ```

1. Enable expanded display mode:

   ```plaintext
   \x
   ```

1. Check `pg_stat_activity`:

   ```sql
   select * from pg_stat_activity where usename='khulnasoft_replication';
   ```

   You should see something like this:

   ```plaintext
   -[ RECORD 1 ]----+------------------------------
   datid            |
   datname          |
   pid              | 81890
   usesysid         | 39897
   usename          | khulnasoft_replication
   application_name | walreceiver
   client_addr      |
   client_hostname  |
   client_port      | -1
   backend_start    | 2021-01-14 16:56:56.190756+00
   xact_start       |
   query_start      |
   state_change     | 2021-01-14 16:56:56.192009+00
   wait_event_type  | Activity
   wait_event       | WalSenderMain
   state            | active
   backend_xid      |
   backend_xmin     |
   query            |
   backend_type     | walsender
   ```

### Secondary

Check the secondary logs with `kdk tail postgresql-replica`. You should see something like this:

```plaintext
2021-01-14_15:46:15.83178 postgresql-replica    : 2021-01-14 15:46:15.831 WET [60837] LOG:  listening on Unix socket "/full/path/to/kdk-root/postgresql-replica/.s.PGSQL.5432"
2021-01-14_15:46:15.87366 postgresql-replica    : 2021-01-14 15:46:15.873 WET [60991] LOG:  entering standby mode
2021-01-14_15:46:15.88190 postgresql-replica    : 2021-01-14 15:46:15.881 WET [60991] LOG:  redo starts at 0/6010EC8
2021-01-14_15:46:15.88241 postgresql-replica    : 2021-01-14 15:46:15.882 WET [60991] LOG:  consistent recovery state reached at 0/6017678
2021-01-14_15:46:15.88274 postgresql-replica    : 2021-01-14 15:46:15.882 WET [60837] LOG:  database system is ready to accept read only connections
2021-01-14_15:47:13.89654 postgresql-replica    : 2021-01-14 15:47:13.896 WET [60991] LOG:  invalid record length at 0/6018598: wanted 24, got 0
2021-01-14_15:47:13.90324 postgresql-replica    : 2021-01-14 15:47:13.903 WET [61711] LOG:  started streaming WAL from primary at 0/6000000 on timeline 1
```

## Debug

Use these instructions if needing to debug database load balancing.

### Query log

If you want to see which queries go to primary and secondary, you can enable statement logging for each instance, editing `postgresql/data/postgresql.conf` and `postgresql-replica/data/postgresql.conf`, respectively:

```plaintext
log_statement = 'all'                        # none, ddl, mod, all
```

Once done, restart the instances with KDK and tail their logs.

### Simulating replication delay

You can simulate replication delay by adding a minimum delay. The
following setting in `postgresql-replica/data/postgresql.conf` delays
replication by at least 1 minute:

```plaintext
recovery_min_apply_delay = '1min'
```

When simulating replication delay, you may never be caught up if some process is constantly writing. If you find Praefect is constantly
updating some status, you can work around this by stopping Praefect temporarily with `kdk stop praefect`.
