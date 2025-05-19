---
title: PostgreSQL
---

KDK users often need to interact with PostgreSQL.

## Access PostgreSQL

### Command-line access

KDK uses the PostgreSQL binaries installed on your system (see [install](../_index.md) section),
but keeps the data files within the KDK directory structure, under `khulnasoft-development-kit/postgresql/data`.

This means that the databases cannot be seen with `psql -l`, but you can use the `kdk psql` wrapper
to access the KDK databases:

```shell
# Connect to the default gitlabhq_development database
kdk psql

# List all databases
kdk psql -l

# Connect to a different database
kdk psql -d gitlabhq_test

# Show all options
kdk psql --help
```

You can also use the Rails `dbconsole` command, but it's much slower to start up:

```shell
cd khulnasoft-development-kit/khulnasoft

# Use default development environment
bundle exec rails dbconsole

# Use a different Rails environment
bundle exec rails dbconsole -e test
```

### GUI access

To access the database using a [GUI SQL client](https://wiki.postgresql.org/wiki/PostgreSQL_Clients), provide the following information:

- Host name: path to data file (for example, `khulnasoft-development-kit/postgresql`) or `localhost` (see the [instructions](https://docs.gitlab.com/ee/development/database/database_debugging.html#access-the-database-with-a-gui) for switching to `localhost`)
- Database port: for example, `5432`
- Database name: for example, `gitlabhq_development` or `gitlabhq_test`
- Username and Password should be left blank

The CLI client is generally more capable. Not all GUI clients support a blank username.

## Upgrade PostgreSQL

There are two ways to upgrade PostgreSQL:

1. [Run the upgrade script](#run-the-upgrade-script)
1. [Dump and restore](#dump-and-restore)

macOS users with Homebrew may find it easiest to use the first approach
since there is a convenient script that makes upgrading a single-line
command. Use the second approach if you are not using macOS or the
script fails for some reason.

## Run the upgrade script

For [systems that support simple installation](../_index.md), there is a convenient script that
automatically runs `pg_upgrade` with the correct parameters:

```shell
support/upgrade-postgresql
```

This script attempts to:

1. Find both the current and target PostgreSQL binaries.
1. Initialize a new `data` directory for the target PostgreSQL version.
1. Upgrade the current `postgresql/data` directory.
1. Back up the original `postgresql/data` directory.
1. Promote the newly-upgraded `data` for the target PostgreSQL version by
   renaming this directory to `postgresql/data`.

## Dump and restore

If the upgrade script does not work, you can also dump the current
contents of the PostgreSQL database and restore it to the new database
version:

1. (Optional) To retain the current database contents, create a backup of the database:

   ```shell
   # cd into your khulnasoft-development-kit directory
   cd khulnasoft-development-kit

   # Start the KDK database
   kdk start db

   # Create a backup of the current contents of the KDK database
   pg_dumpall -l gitlabhq_development -h "$PWD/postgresql"  -p 5432 > db_backup

   kdk stop db
   ```

1. Remove the current PostgreSQL `data` folder:

   ```shell
   # Backup the current data folder
   mv postgresql/data postgresql/data.bkp
   ```

1. Upgrade your PostgreSQL installation to a newer version. For example, to upgrade to
   PostgreSQL 12 on macOS using Homebrew:

   ```shell
   brew install postgresql@12
   ```

   If you are using [`mise`](mise.md), the KDK [.tool-versions](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/.tool-versions) file includes required PostgreSQL versions, which can be installed by running:

   ```shell
   mise install
   ```

1. Initialize a new data folder with the new version of PostgreSQL by running `make`:

   ```shell
   make postgresql/data
   ```

1. Restore the backup:

   ```shell
   # Start the database.
   kdk start db

   # Restore the contents of the backup into the new database.
   kdk psql -d postgres -f db_backup
   ```

Your KDK should now be ready to use.

## Upgrading the secondary database

If you have replication configured, after you have upgraded the primary database, do the following to upgrade the secondary database as well:

1. Remove the old secondary database data as we will be replacing it with primary database data:

   ```shell
   rm -rf postgresql-replica/data
   ```

1. Copy data from primary to secondary with `pg_basebackup`:

   ```shell
   pg_basebackup -R -h $(pwd)/postgresql -D $(pwd)/postgresql-replica/data -P -U khulnasoft_replication --wal-method=fetch
   ```

## Access Geo Secondary Database

```shell
# Connect to the default gitlabhq_geo_development database
kdk psql-geo

# List all databases
kdk psql-geo -l

# Connect to a different database
kdk psql-geo -d gitlabhq_geo_test

# Show all options
kdk psql-geo --help
```

## Troubleshooting

### Error while installing PostgreSQL 16: ICU library not found

You might encounter this error after running `mise install postgres 16.2`:

```plaintext
checking whether to build with ICU support... yes
checking for icu-uc icu-i18n... no
configure: error: ICU library not found
If you have ICU already installed, see config.log for details on the
failure.  It is possible the compiler isn't looking in the proper directory.
Use --without-icu to disable ICU support.
```

To resolve the issue:

1. Check your `icu4c` information:

   ```shell
   brew info icu4c
   ```

1. Follow the provided instructions:

   ```plaintext
   For pkg-config to find icu4c you may need to set:
     export PKG_CONFIG_PATH="/opt/homebrew/opt/icu4c/lib/pkgconfig"
   ```
