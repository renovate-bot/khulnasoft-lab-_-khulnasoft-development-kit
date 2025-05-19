---
title: KhulnaSoft Geo
---

This document instructs you to set up KhulnaSoft Geo using KDK.

Geo allows you to replicate a whole KhulnaSoft instance. Customers use this for
Disaster Recovery, as well as to offload read-only requests to secondary
instances. For more information, see the
[Geo solutions page](https://about.khulnasoft.com/solutions/geo/) or
the [Geo documentation](https://docs.khulnasoft.com/ee/administration/geo).

## Easy installation

### How to install 2 KDKs and configure Geo

The installation script:

- Clones the KDK project into a new `kdk` directory in the current working directory.
- Installs the required software versions.
- Runs `kdk install`.
- Runs `kdk start`.
- Adds your license.
- Clones the KDK project into a new `kdk2` directory in the current working directory.
- Runs `./support/geo-add-secondary` (see below for a description of this script).

1. Follow the [dependency installation instructions](../_index.md#install-prerequisites).

1. Set the `KHULNASOFT_LICENSE_KEY` environment variable in your shell, with the text of a KhulnaSoft Premium or Ultimate license key.

   If you have a file on disk, then run:

   ```shell
   export KHULNASOFT_LICENSE_KEY=$(cat /path/to/your/premium.khulnasoft-license)
   ```

   Or, if you have plaintext, then run:

   ```shell
   export KHULNASOFT_LICENSE_KEY="pasted text"
   ```

1. Run the installation script:

   ```shell
   curl "https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/raw/master/support/geo-install" | bash
   ```

   Or, if you want to name the KDK directories, then run:

   ```shell
   curl "https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/raw/master/support/geo-install" | bash -s name-of-primary name-of-secondary
   ```

To check if it is working, visit the unified URL at `http://127.0.0.1:3001` and sign in. Your requests are always served by the secondary site (as if Geo-location based DNS is set up and you are located near the secondary site). It should behave no differently than the primary site. That is the goal anyway.

If needed, you can visit the primary directly at `http://127.0.0.1:3000` but this would be considered a workaround, and you may notice quirks. For example, absolute URLs rendered on the page use the unified URL. You may also occasionally get redirected to the unified URL.

To see if you are able to run tests, you can run a simple spec like `bin/rspec ee/spec/lib/khulnasoft/geo/logger_spec.rb` from the `khulnasoft` directory in the primary `kdk` directory.

## Advanced Installation

Please visit [KhulnaSoft Geo - Advanced Installation](geo/advanced_installation.md).

## Running tests

### On a primary

To run secondary-site tests on your primary KDK, you must configure the Geo
tracking test database connection in the **primary** KDK by running:

```shell
kdk config set geo.experimental.allow_secondary_tests_in_primary true
kdk reconfigure
```

KDK should then automatically create the test Geo tracking database, and you
should be able to run tests which require this database.

If you want to manually run a Rails DB task on the test Geo tracking
database in your primary KDK, then you must specify `RAILS_ENV=test`, because a
Geo tracking database connection is configured in `database.yml` in `test` but
not in `development`. For example,
`RAILS_ENV=test bin/rails db:test:prepare:geo` works, but
`bin/rails db:test:prepare:geo` fails with
`Don't know how to build task 'db:test:prepare:geo'`, since
`RAILS_ENV=development` is implied.

### On a secondary

You should be able to run tests on KDKs that are configured as secondary sites,
with no manual or special configuration.

For reference, when a KDK is configured as a Geo secondary site, the test
environment database connections for the `main` and `ci` databases are
automatically configured to use the tracking database in `database.yml`. This is
done so that tests can run on the secondary site, because otherwise the tests would fail while inserting or updating data into the read-only `main` or
`ci` databases.

## SSH cloning

If you used the [Easy installation](#easy-installation), then your primary site's SSH service is disabled, and your secondary site's SSH service is enabled. The listen port is unchanged. This simulates having a unified URL for SSH which happens to always route to the secondary site. With this setup, you can already observe Geo-specific behavior. For example, when you do a Git push, you will see `This request to a Geo secondary node will be forwarded to the Geo primary node`.

You can enable the primary site's SSH service, but you will need to specify non-default ports so they don't conflict with the secondary site's ports. For example, in your primary site's `kdk.yml`:

```yaml
sshd:
  enabled: true
  listen_port: 2223
  web_listen: localhost:9123 # the default is 9122
```

Or vice versa, you can specify non-default ports for your secondary site.

Note that the Git clone over SSH URL found in project show pages will always display the primary site's Git SSH URL, even if the primary site's SSH service is disabled. There is [an issue](https://github.com/khulnasoft-lab/khulnasoft/-/issues/370377) to improve this behavior.

For more information, see [SSH](ssh.md).

## Updating KDKs

1. Use `kdk update` on the primary KDK.
1. Use `kdk update` on the secondary KDK.

## Upgrading PostgreSQL

Upgrading to a newer Postgres version is not automated in KDK with Geo.

It should be possible to manually accomplish an upgrade, but if you are not generally familiar with the process,
it is recommended to set up your KDKs from scratch.

## Troubleshooting

### `postgresql-geo/data` exists but is not empty

If you see this error during setup because you have already run `make geo-secondary-setup` once:

```plaintext
initdb: directory "postgresql-geo/data" exists but is not empty
If you want to create a new database system, either remove or empty
the directory "postgresql-geo/data" or run initdb
with an argument other than "postgresql-geo/data".
make: *** [postgresql/geo] Error 1
```

Then you may delete or move that data in order to run `make geo-secondary-setup` again.

```shell
mv postgresql-geo/data postgresql-geo/data.backup
```

### KDK update command error on secondaries

You see the following error after running `kdk update` on your local Geo
secondary. It is ok to ignore. Your local Geo secondary does not have or need a
test DB, and this error occurs on the very last step of `kdk update`.

```shell
cd /Users/foo/Developer/kdk-geo/khulnasoft && \
      bundle exec rake db:migrate db:test:prepare
rake aborted!
ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute DROP DATABASE in a read-only transaction
: DROP DATABASE IF EXISTS "khulnasofthq_test"
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `load'
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `<main>'

Caused by:
PG::ReadOnlySqlTransaction: ERROR:  cannot execute DROP DATABASE in a read-only transaction
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `load'
/Users/foo/.rbenv/versions/2.6.3/bin/bundle:23:in `<main>'
Tasks: TOP => db:test:load => db:test:purge
(See full trace by running task with --trace)
make: *** [khulnasoft-update] Error 1
```

## Enabling Docker Registry replication

For information on enabling Docker Registry replication in KDK, see
[Docker Registry replication](geo-docker-registry-replication.md).
