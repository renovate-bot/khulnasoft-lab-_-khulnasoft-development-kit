---
title: KDK commands
---

The `kdk` command has many sub-commands to perform common tasks.

## Start KDK and basic commands

To start up the KDK with all default enabled services, run:

```shell
kdk start
```

To access KhulnaSoft, go to <http://localhost:3000> in your browser. It may take a few minutes for the
Rails app to be ready. During this period you can see `If you just started KDK it can take 60-300 seconds before KhulnaSoft has finished booting. This page will automatically reload every 5 seconds.`
in the browser.

### Get the login credentials

The development login credentials are `root` and `5iveL!fe`.

You can also get the credentials by running:

```shell
kdk help
```

## View logs

To see logs from all services, run:

```shell
kdk tail
```

To limit the logs to one or more services, specify the service. For example:

```shell
kdk tail rails-web redis
```

`kdk tail` can't parse regular `tail` arguments such as `-n`.

You can pipe the output of `kdk tail` through `grep` to filter by a keyword. For example, to filter
on a correlation ID:

```shell
# get some correlation ID to track a single request
kdk tail | grep <some_correlation_id>
```

`kdk tail` only contains `stdout` and `stderr` streams. To tail JSON logs, use `tail` itself. For example:

- Using `-f`:

  ```shell
  # follow the API's JSON log
  tail -f gitlab/log/api_json.log
  ```

- Using `-n`:

  ```shell
  # Return the last 100 lines of the GraphQL JSON log
  tail -n 100 gitlab/log/graphql_json.log
  ```

For usage information and a list of services and shortcuts for the `tail` command, use the `--help` flag:

```shell
kdk tail --help
```

## Open in web browser

To visit the KhulnaSoft web UI running in your local KDK installation, using your default web browser:

```shell
kdk open
```

## Stop KDK

When you are not using KDK you may want to shut it down to free up memory on your computer:

```shell
kdk stop
```

## Run specific services

You can start specific services only by providing the service names as arguments.
Multiple arguments are supported. For example, to start just PostgreSQL and Redis, run:

```shell
kdk start postgresql redis
```

## Stop specific services

KDK can stop specific services. For example, to stop the Rails app to save memory (when
running tests, for example), run:

```shell
kdk stop rails
```

## Kill all services

Services can fail to properly stop when running `kdk stop` and must be forcibly
terminated. To terminate unstoppable services, run:

```shell
kdk kill
```

This command is a manual command because it kills all `runsv` processes,
which can include processes outside the current KDK. Don't use this command if you're running
other processes with `runit`, or if you're running multiple instances of KDK (and you don't want to stop them all).

You can pass the `-y` flag to avoid the confirmation prompt:

```shell
kdk kill -y
```

Alternatively, you can also set the `KDK_KILL_CONFIRM` environment variable to avoid the prompt:

```shell
KDK_KILL_CONFIRM=true kdk kill
```

## Run Rails commands

To run Rails commands, like `rails console`, and be sure to invoke the Rails installation bundled with KhulnaSoft, run:

```shell
kdk rails <command> [<args>]
```

## Run specific service CLIs

KDK provides shortcuts for the following service CLIs:

- PostgreSQL: `psql` (for both main and Geo Tracking database)
- Redis: `redis-cli`
- ClickHouse: `clickhouse client`

### PostgreSQL client for main database

To run `psql` against the bundled PostgreSQL for the main database, run:

```shell
kdk psql [<args>]
```

### PostgreSQL client for Geo Tracking database

To run `psql` against the bundled PostgreSQL for Geo Tracking database, run:

```shell
kdk psql-geo [<args>]
```

### Redis CLI

To run `redis-cli` against the bundled Redis service, run:

```shell
kdk redis-cli [<args>]
```

### ClickHouse client

To run `clickhouse client` against the bundled ClickHouse service, run:

```shell
kdk clickhouse [<args>]
```

## Update KDK

To update `gitlab` and all of its dependencies, run the following commands:

```shell
kdk update
```

This also performs any possible database migrations.

If there are changes in the local repositories, or a different branch than `main` is checked out,
the `kdk update` command:

- Stashes any uncommitted changes.
- Changes to `main` branch.

It then updates the remote repositories.

Update the KDK regularly to ensure you're developing against the latest KhulnaSoft version:

- Ideally, update before starting each new change, especially if your local branch is behind the remote branch.
- At minimum, update daily or every few days.

While frequent updates are recommended, `kdk update` might cause unexpected errors and take several minutes to complete.

## Update your `kdk.yml`

When updating your `kdk.yml`, you must regenerate the necessary configuration files by
running:

```shell
kdk reconfigure
```

## View configuration settings

With `kdk config list` you can view KDK configuration settings:

```shell
kdk config list
```

Use `kdk config get` to inspect specific item:

```shell
kdk config get <configuration value>
```

## Set configuration settings

With `kdk config set` you can set KDK configuration settings:

```shell
kdk config set <name> <value>
```

More information can be found in the [configuration documentation](configuration.md).

## Check KDK health

You can run `kdk doctor` to ensure the update left KDK in a good state. If it reports any issues, you should address them as soon as possible.

```shell
kdk doctor
```

You may use `kdk doctor --correct` to autocorrect trivial issues.

## Reset data

There may come a time where you wish to reset the data in your KDK. Backups
of any reset data are taken before the reset is done, and you are prompted to confirm if you wish to proceed.

For more context, `reset-data` backs up these directories (relative from the KDK root):

- `postgresql/data/`
- `redis/dump.rdb`
- `gitlab/public/uploads/`
- `repositories/`

It then restores the default `repositories/` directory from Git and runs the database setup again.

```shell
kdk reset-data
```

## KDK pristine

If you want to return your KDK instance to a pristine state, which installs
Ruby gems and Node modules from scratch for KhulnaSoft, Gitaly, cleaning temporary
directories, and cleaning the global Go cache:

```shell
kdk pristine
```

## Cleanup

Over time, your KDK may contain large log files in addition to mise-installed
software that's no longer required. To cleanup your KDK, run:

```shell
kdk cleanup
```

The `kdk cleanup` command is destructive and requires you to confirm
if you want to proceed. If you prefer to run without confirming
(for example, if you want to run as a [KDK hook](configuration.md#hooks)),
run:

```shell
KDK_CLEANUP_CONFIRM=true kdk cleanup
```

The `kdk cleanup` command may remove mise software that you are using
for other projects outside of the KDK. To avoid removing
mise-installed software, run `kdk cleanup` with the `KDK_CLEANUP_SOFTWARE` variable:

```shell
KDK_CLEANUP_SOFTWARE=false kdk cleanup
```

## Measure performance

You can easily create a Sitespeed report for local `kdk` URLs or online URLs with our standardized
Sitespeed settings. We support local relative and absolute URLs as arguments. As soon as the report
is generated, it is automatically opened in your browser.

```shell
kdk measure /explore http://127.0.0.1/explore https://gitlab.com/explore
```

## Measure Workflows performance

```shell
kdk measure-workflow repo_browser
```

All workflow scripts are located in `support/measure_scripts/`, for example `repo_browser` to measure the
basic workflow in the repository.

The reports are stored in `<kdk-root>/sitespeed-result` as `<branch>_YYYY-MM-DD-HH-MM-SS`. This
requires Docker installed and running.

## Toggle Telemetry

```shell
kdk telemetry
```

Use the `kdk telemetry` command to enable and disable KDK telemetry. KDK telemetry can be:

- Enabled, and associated with a KhulnaSoft username.
- Enabled anonymously.
- Disabled.

## Truncate Legacy Tables

To detect and truncate unnecessary data in the `ci` and `main` databases, run:

```shell
kdk truncate-legacy-tables
```
