---
title: Troubleshooting PostgreSQL
---

[[_TOC_]]

The following are possible solutions to problems you might encounter with PostgreSQL and KDK.

## Postgres 16.8 installation

### Error: `'strchrnul' is only available on macOS 15.4 or newer`

You might get this error when compiling PostgreSQL 16.8 or the `pg_query` gem on macOS.
It's a [known issue](https://www.postgresql.org/message-id/385134.1743523038%40sss.pgh.pa.us) between PostgreSQL 16.8 and macOS 15.4.

To resolve this:

1. Update your macOS to the latest version.
1. Run `kdk update` to apply our built-in workarounds.
1. If installing directly with mise, run:

   ```shell
   source .kdkrc && mise install postgres@16.8
   ```

### Error: `pg_dump: error: server version: 16.8; pg_dump version: 14.9`

This version mismatch occurs when your local `khulnasoft/` repository contains a `.tool-versions` file
with an older PostgreSQL version (14.9).

To resolve this:

1. Update your local branch:

   ```shell
   git pull origin master
   ```

1. If you have local changes:

   ```shell
   git stash
   git pull origin master
   git stash pop
   ```

### Error: `configure: error: ICU library not found`

This is a [known issue](https://github.com/mise-plugins/mise-postgres?tab=readme-ov-file#mac) with the mise PostgreSQL plugin.

To resolve this:

1. Run `kdk update` to apply our built-in workarounds.
1. If that fails, run:

   ```shell
   source .kdkrc && mise install postgres@16.8
   ```

1. If the previous methods don't resolve the issue, set the environment variables manually:

   ```shell
   PKG_CONFIG_PATH="$(brew --prefix icu4c)/lib/pkgconfig" \
   LDFLAGS="-L$(brew --prefix icu4c)/lib" \
   CPPFLAGS="-I$(brew --prefix icu4c)/include" \
   mise install postgres@16.8
   ```

## `kdk update` leaves `khulnasoft/db/` with uncommitted changes

When you run `kdk update`, you can have uncommitted changes in `khulnasoft/db/`. For more information, see
[issue 300251](https://github.com/khulnasoft-lab/khulnasoft/-/issues/300251).

To avoid leaving uncommitted changes in `khulnasoft/db/` from a `kdk update`, either:

- If you are unfamiliar with `db/`, add [KDK hook](../configuration.md#hooks) to your
  `kdk.yml`:

  ```yaml
  kdk:
    update_hooks:
      after:
        - cd khulnasoft && git checkout db/*
  ```

- Refer to the developer documentation for
  [schema changes](https://docs.khulnasoft.com/ee/development/migration_style_guide.html#schema-changes).

## Unable to build and install `pg` gem on KDK install

After installing PostgreSQL with brew, you have to set the proper path to PostgreSQL.
You may run into the following errors on running `kdk install`

```plaintext
ERROR:  Error installing pg:
        ERROR: Failed to build gem native extension.

    current directory: /usr/local/bundle/gems/pg-1.3.5/ext
/usr/local/bin/ruby -I /usr/local/lib/ruby/2.7.0 -r ./siteconf20220614-29-ofphd.rb extconf.rb
Calling libpq with GVL unlocked
checking for pg_config... no
checking for libpq per pkg-config... no
Using libpq from
checking for libpq-fe.h... no
Can't find the 'libpq-fe.h header
*****************************************************************************

Unable to find PostgreSQL client library.

Please install libpq or postgresql client package like so:
  sudo apt install libpq-dev
  sudo yum install postgresql-devel
  sudo zypper in postgresql-devel
  sudo pacman -S postgresql-libs

or try again with:
  gem install pg -- --with-pg-config=/path/to/pg_config

or set library paths manually with:
  gem install pg -- --with-pg-include=/path/to/libpq-fe.h/ --with-pg-lib=/path/to/libpq.so/

*** extconf.rb failed ***

  [...]

An error occurred while installing pg (1.3.5), and Bundler cannot continue.
Make sure that `gem install pg -v '1.3.5' --source 'https://rubygems.org/'` succeeds before bundling.
```

This is because the script fails to find the PostgreSQL instance in the path.
The instructions for this may show up after installing PostgreSQL.
The example below is from running `brew install postgresql@12` on a macOS installation.
For other versions, other platform install and other shell terminal please adjust the path accordingly.

```plaintext
If you need to have this software first in your PATH run:
  echo 'export PATH="/usr/local/opt/postgresql@12/bin:$PATH"' >> ~/.bash_profile
```

Once this is set, run the `kdk install` command again.

## Error in database migrations when pg_trgm extension is missing

Since KhulnaSoft 8.6+ the PostgreSQL extension `pg_trgm` must be installed. If you
are installing KDK for the first time this is handled automatically from the
database schema. In case you are updating your KDK and you experience this
error, make sure you pull the latest changes from the KDK repository and run:

```shell
./support/enable-postgres-extensions
```

## PostgreSQL is looking for wrong version of icu4c

If the Rails server cannot connect to PostgreSQL and you see the following when running `kdk tail postgresql`:

```plaintext
2020-07-06_00:26:20.51557 postgresql            : support/postgresql-signal-wrapper:16:in `<main>': undefined method `exitstatus' for nil:NilClass (NoMethodError)
2020-07-06_00:26:21.62892 postgresql            : dyld: Library not loaded: /usr/local/opt/icu4c/lib/libicui18n.66.dylib
2020-07-06_00:26:21.62896 postgresql            :   Referenced from: /usr/local/opt/postgresql@11/bin/postgres
2020-07-06_00:26:21.62897 postgresql            :   Reason: image not found
```

This means the PostgreSQL is trying to load an older version of `icu4c` (`66` in the example), and failing.
This can happen when `icu4c` is not pinned and is upgraded beyond the version supported
by PostgreSQL.

To resolve this, reinstall PostgreSQL with:

```shell
brew reinstall postgresql@12
```

## ActiveRecord::PendingMigrationError at /

After running the KhulnaSoft Development Kit using `kdk start` and browsing to `http://localhost:3000/`, you may see an error page that says `ActiveRecord::PendingMigrationError at /. Migrations are pending`.

To fix this error, the pending migration must be resolved. Perform the following steps in your terminal:

1. Change to the `khulnasoft` directory using `cd khulnasoft`
1. Run the following command to perform the migration: `rails db:migrate RAILS_ENV=development`

Once the operation is complete, refresh the page.

## Database files incompatible with server

If you see `FATAL: database files are incompatible with server` errors, it means
the PostgreSQL data directory was initialized by an old PostgreSQL version, which
is not compatible with your current PostgreSQL version.

You can solve it in one of two ways, depending if you would like to retain your data or not:

### If you do not need to retain your data

Note that this wipes out the existing contents of your database.

```shell
# cd into your KDK folder
cd khulnasoft-development-kit

# Remove your existing data
mv postgresql/data postgresql/data.bkp

# Initialize a new data folder
make postgresql/data

# Initialize the khulnasofthq_development / khulnasofthq_development_ci database
kdk reconfigure

# Start your database.
kdk start postgresql
```

You may remove the `data.bkp` folder if your database is working well.

### If you would like to retain your data

Check the version of PostgreSQL that your data is compatible with:

```shell
# cd into your KDK folder
cd khulnasoft-development-kit

cat postgresql/data/PG_VERSION
```

If the content of the `PG_VERSION` file is `12`, your data folder is compatible
with PostgreSQL 12.

Downgrade your PostgreSQL to the compatible version. For example, to downgrade to
PostgreSQL 12 on macOS using Homebrew:

```shell
brew install postgresql@12
brew link --force postgresql@12
```

You also need to update your `Procfile` to use the downgraded PostgreSQL binaries:

```shell
# Change Procfile to use downgraded PostgreSQL binaries
kdk reconfigure
```

You can now follow the steps described in [Upgrade PostgreSQL](../howto/postgresql.md#upgrade-postgresql)
to upgrade your PostgreSQL version while retaining your current data.

## Rails cannot connect to PostgreSQL

- Use `kdk status` to see if `postgresql` is running.
- Check for custom PostgreSQL connection settings defined via the environment; we
  assume none such variables are set. Look for them with `set | grep '^PG'`.

## Fix conflicts in database migrations if you use the same db for CE and EE

> [!note]
> The recommended way to fix the problem is to rebuild your database and move
> your EE development into a new directory.

In case you use the same database for both CE and EE development, sometimes you
can get stuck in a situation when the migration is up in `rake db:migrate:status`,
but in reality the database doesn't have it.

For example, <https://github.com/khulnasoft-lab/khulnasoft-foss/merge_requests/3186>
introduced some changes when a few EE migrations were added to CE. If you were
using the same db for CE and EE you would get hit by the following error:

```shell
undefined method `share_with_group_lock' for #<Group
```

This exception happened because the system thinks that such migration was
already run, and thus Rails skipped adding the `share_with_group_lock` field to
the `namespaces` table.

The problem is that you can not run `rake db:migrate:up VERSION=xxx` since the
system thinks the migration is already run. Also, you can not run
`rake db:migrate:redo VERSION=xxx` since it tries to do `down` before `up`,
which fails if column does not exist or can cause data loss if column exists.

A quick solution is to remove the database data and then recreate it:

```shell
bundle exec rake setup
```

---

If you don't want to nuke the database, you can perform the migrations manually.
Open a terminal and start the rails console:

```shell
rails console
```

And run manually the migrations:

```plaintext
require Rails.root.join("db/migrate/20130711063759_create_project_group_links.rb")
CreateProjectGroupLinks.new.change
require Rails.root.join("db/migrate/20130820102832_add_access_to_project_group_link.rb")
AddAccessToProjectGroupLink.new.change
require Rails.root.join("db/migrate/20150930110012_add_group_share_lock.rb")
AddGroupShareLock.new.change
```

You should now be able to continue your development. You might want to note
that in this case we had 3 migrations happening:

```plaintext
db/migrate/20130711063759_create_project_group_links.rb
db/migrate/20130820102832_add_access_to_project_group_link.rb
db/migrate/20150930110012_add_group_share_lock.rb
```

In general it doesn't matter in which order you run them, but in this case
the last two migrations create columns in a table which is created by the first
migration. So, in this example the order is important. Otherwise you would try
to create a column in a non-existent table which would of course fail.

## Delete non-existent migrations from the database

If for some reason you end up having database migrations that no longer exist
but are present in your database, you might want to remove them.

1. Find the non-existent migrations with `rake db:migrate:status`. You should
   see some entries like:

   ```plaintext
   up     20160727191041  ********** NO FILE **********
   up     20160727193336  ********** NO FILE **********
   ```

1. Open a rails database console with `rails dbconsole`.
1. Delete the migrations you want with:

   ```sql
   DELETE FROM schema_migrations WHERE version='20160727191041';
   ```

You can now run `rake db:migrate:status` again to verify that the entries are
deleted from the database.

## Truncate legacy data from `main` and `ci` databases

It is possible that you see errors on the `ci` or `main` database while performing migrations, like the one below:

```ruby
ci: == 20221107220420 ValidateNotNullConstraintOnMemberNamespaceId: migrating =====
ci: -- current_schema()
ci:    -> 0.0002s
ci: -- execute("ALTER TABLE members VALIDATE CONSTRAINT check_508774aac0;")
rails aborted!
StandardError: An error has occurred, all later migrations canceled:

PG::CheckViolation: ERROR:  check constraint "check_508774aac0" is violated by some row
```

This is because there is stale data on the `ci` database on tables belonging to the `main` database (or vice-versa).

Such data should be truncated. To do this, you can run:

```shell
kdk truncate-legacy-tables
```

## Fix a build error with `pgvector` extension due to XCode SDK path changes on macOS

If you encounter a build error with the `pgvector` extension while upgrading PostgreSQL, it could be due to XCode SDK path changes by macOS or XCode upgrades. This error occurs when the XCode SDK path is not configured correctly for the extension.

To fix this error, perform the following steps in your terminal:

1. Ensure that the `pgvector` extension is already installed. If not, install it before continuing.
1. Clean and reinstall the extension to recompile the library with the correct `ifdef`. This change was added in the extension
   to manage changes introduced in PostgreSQL 13:

   ```shell
   cd pgvector
   make clean && make install
   ```

   Here, `make clean` is necessary to recompile the `pgvector` extension with the correct updates for PostgreSQL 13.

1. During the `make install` process, you might encounter an error related to the `sysroot` directory path:

   ```shell
   clang: warning: no such sysroot directory: '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX13.0.sdk' [-Wmissing-sysroot]
   ```

   This error occurs because the `isysroot` parameter in `pg_config` is pointing to the wrong path. To fix this, you should uninstall and reinstall PostgreSQL using the following commands:

   ```shell
   mise uninstall postgres <version>
   mise install postgres <version>
   ```

1. Once the reinstallation is complete, run `make install` again.
1. After you've fixed the build error, run the `support/upgrade-postgresql` to upgrade your PostgreSQL version.

## Error: `invalid primary checkpoint record`

If Postgres reports an `invalid primary checkpoint record`
or `could not locate a valid checkpoint record` during startup, the
transaction log is likely corrupt.

You can reset the transaction/write-ahead log by running the following
command. Be careful, this can cause data loss.

```shell
$ pg_resetwal $(kdk config get postgresql.data_dir)
Write-ahead log reset
```

For more information, see [this thread](https://stackoverflow.com/a/8812934).

## Additional Debugging

Additional information can be found in [the docs](https://docs.khulnasoft.com/ee/development/database/database_debugging.html).
