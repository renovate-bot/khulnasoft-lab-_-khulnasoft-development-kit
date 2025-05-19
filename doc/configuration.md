---
title: Configuration
---

This document describes how you can configure your KDK environment.

- [Git configuration](#git-configuration).
- [KDK configuration](#kdk-configuration).
- [Runner settings](#runner-settings).
- [Vite settings](#vite-settings).
- [Webpack settings](#webpack-settings).
- [ActionCable settings](#actioncable-settings).
- [Grafana settings](#grafana-settings).
- [`asdf` settings](#asdf-settings).
- [IDE settings](#ide-settings).
- [Environment variables](#environment-variables).

## Git configuration

Git has features which are disabled by default, and would be great to enable to
be more effective with Git. Run `rake git:configure` to set the recommendations
for some repositories within the KDK.

To set the configuration globally, run `rake git:configure[true]`. When using
`zsh`, don't forget to escape the square brackets: `rake git:configure\[true\]`.

## KDK configuration

KDK can be configured using [`kdk.yml`](#kdkyml) configuration file.

### `kdk.yml`

You can override the KDK default settings with a `kdk.yml` in the KDK root,
which is the only supported configuration method.

To see available configuration settings, see [`kdk.example.yml`](../kdk.example.yml).

This file contains all possible settings with example values. Note
that these values may not be the default that KDK uses.

If you want to check which settings are in place, you can run `rake dump_config`, which prints
all applied settings in a YAML structure.

- [Notable settings](#notable-settings)
- [KDK settings](#kdk-settings)
- [KhulnaSoft settings](#khulnasoft-settings)
- [KhulnaSoft Docs settings](#khulnasoft-docs-settings)
- [Additional projects settings](#additional-projects-settings)
- [NGINX settings](#nginx-settings)

#### Run KhulnaSoft and KhulnaSoft FOSS concurrently

To have multiple KDK instances running concurrently, for example to test KhulnaSoft and KhulnaSoft FOSS,
initialize each into a separate KDK folder. To run them simultaneously, make sure they don't use
conflicting port numbers.

For example, to start KDK ports at `5000` instead of the default `3000`:

1. Run `kdk config set port_offset 5000` to update `kdk.yml`.
1. Run `bundle exec rake claimed_ports` to verify the change.
1. Run `kdk reconfigure` to apply the configuration changes.

Now, KDK runs on port 5000, workhorse on 5007 etc.

#### Overwriting configuration files

Any configuration file managed by KDK is overwritten
whenever there are changes in its source (a `.example` or `.erb`
file). When KDK overwrites a configuration file it moves the original file
into the `.backups` subdirectory of your KDK installation.

If you have local changes that you don't want KDK to touch you can
protect individual configuration files. For example:

```yaml
# in kdk.yml
kdk:
  protected_config_files:
  - 'gitaly/*.toml'
```

> [!note]
> `kdk.yml` is not managed by KDK and KDK never overwrites it.

#### Notable settings

Here are a few settings worth mentioning:

| Setting                          | Default               | Description                                                                                |
|--------------------------------- |-----------------------|--------------------------------------------------------------------------------------------|
| `listen_address`                 | `127.0.0.1`           | Select the IP for KDK to listen on. Note, this is occasionally used as a hostname/URL (when running feature specs for example), so using 0.0.0.0 can be problematic. |
| `port`                           | `3000`                | Select the port to run KDK on, useful when running multiple KDKs in parallel.              |
| `port_offset`                    | `0`                   | Base value added to all KDK port numbers. Enables running multiple KDK instances simultaneously without port conflicts. |
| `webpack.port`                   | `3808`                | Also useful to configure when running KDKs in parallel. [See below for more webpack options](#webpack-settings). |
| `khulnasoft.rails.bundle_gemfile`    | `Gemfile`             | Set this to where KhulnaSoft should look for Gemfile. |
| `khulnasoft.cache_classes`           | `false`               | Set this to `true` to disable the automatic reloading of Ruby classes when Ruby code is changed. |
| `khulnasoft.default_branch`          |  `master`             | Set this to the desired default branch name in the KhulnaSoft repository. |
| `khulnasoft.gitaly_disable_request_limits`  | `false`        | Set this to `true` to disable Gitaly request limit checks in development. |
| `khulnasoft_pages.host`              | `127.0.0.1.nip.io`    | Specify KhulnaSoft Pages hostname. See also the [Pages guide](howto/pages.md#hostname). |
| `khulnasoft_pages.port`              | `3010`                | Specify on which port KhulnaSoft Pages should run. See also the [Pages guide](howto/pages.md#port). |
| `relative_url_root`              | `/`                   | When you want to test KhulnaSoft being available on a different path than `/`. For example, `/khulnasoft`. |
| `object_store.enabled`           | `false`               | Set this to `true` to enable Object Storage with MinIO.                                    |
| `object_store.consolidated_form` | `false`               | Set this to `true` to use the [consolidated object storage configuration](https://docs.khulnasoft.com/ee/administration/object_storage.html#consolidated-object-storage-configuration). Required for Microsoft Azure. |
| `object_store.connection`        | See `kdk.example.yml` | Specify the [object storage connection settings](https://docs.khulnasoft.com/ee/administration/object_storage.html#connection-settings). |
| `registry.enabled`               | `false`               | Set this to `true` to enable container registry.                                           |
| `geo.enabled`                    | `false`               | Set this to `true` to enable Geo (for now it just enables `postgresql-geo` and `geo-cursor` services). |
| `khulnasoft.rails.puma.workers`      | `2`                   | Set this to `0` to prevent Puma (webserver) running in a [Clustered mode](https://github.com/puma/puma/blob/master/docs/architecture.md). Running in Single mode provides significant memory savings if you work within a [memory-constrained environment](https://khulnasoft.com/groups/khulnasoft-org/-/epics/5303). |
| `restrict_cpu_count`             | `-1` (not restricted) | Set the number of CPUs used when calling `bundle`. Defaults to using the number of CPUs available. |
| `khulnasoft_ai_gateway.enabled`     | 'false'             | Set this to `true` to configure KhulnaSoft AI Gateway to run locally in KDK |

For example, to change the port KDK is accessible on, you can set this in your `kdk.yml`:

```yaml
port: 3001
```

And run the following command to apply the change:

```shell
kdk reconfigure
```

##### Object storage configuration

The following examples are a quick guide for configuring object storage
for external S3 providers, Google Cloud Storage, or Microsoft Azure.
See the [object storage settings](https://docs.khulnasoft.com/ee/administration/object_storage.html).
You should set `consolidated_form` to `true`.

In development, you may also use a single bucket for testing.

###### External S3 providers

```yaml
object_store:
  enabled: true
  consolidated_form: true
  connection:
    provider: 'AWS'
    aws_access_key_id: '<YOUR AWS ACCESS KEY ID>'
    aws_secret_access_key: '<YOUR AWS SECRET ACCESS KEY>'
  objects:
    artifacts:
      bucket: artifacts
    backups:
      bucket: backups
    external_diffs:
      bucket: external-diffs
    lfs:
      bucket: lfs-objects
    uploads:
      bucket: uploads
    packages:
      bucket: packages
    dependency_proxy:
      bucket: dependency_proxy
    terraform_state:
      bucket: terraform
    pages:
      bucket: pages
    ci_secure_files:
      bucket: ci-secure-files
```

###### Google Cloud Storage

```yaml
object_store:
  enabled: true
  consolidated_form: true
  connection:
    provider: 'Google'
    google_project: '<YOUR GOOGLE PROJECT ID>'
    google_json_key_location: '<YOUR PATH TO GCS CREDENTIALS>'
  objects:
    artifacts:
      bucket: artifacts
    backups:
      bucket: backups
    external_diffs:
      bucket: external-diffs
    lfs:
      bucket: lfs-objects
    uploads:
      bucket: uploads
    packages:
      bucket: packages
    dependency_proxy:
      bucket: dependency_proxy
    terraform_state:
      bucket: terraform
    pages:
      bucket: pages
    ci_secure_files:
      bucket: ci-secure-files
```

###### Microsoft Azure Blob storage

To make Microsoft Azure Blob storage work, `consolidated_form` must be
set to `true`:

```yaml
object_store:
  enabled: true
  consolidated_form: true
  connection:
    provider: 'AzureRM'
    azure_storage_account_name: '<YOUR AZURE STORAGE ACCOUNT>'
    azure_storage_access_key: '<YOUR AZURE STORAGE ACCESS KEY>'
  objects:
    artifacts:
      bucket: artifacts
    backups:
      bucket: backups
    external_diffs:
      bucket: external-diffs
    lfs:
      bucket: lfs-objects
    uploads:
      bucket: uploads
    packages:
      bucket: packages
    dependency_proxy:
      bucket: dependency_proxy
    terraform_state:
      bucket: terraform
    pages:
      bucket: pages
    ci_secure_files:
      bucket: ci-secure-files
```

#### KDK settings

There are also a few settings that configure the behavior of KDK itself:

| Setting                           | Default | Description                                                                                      |
|-----------------------------------|---------|--------------------------------------------------------------------------------------------------|
| `kdk.ask_to_restart_after_update` | `true`  | Set this to `false` if you do not wish to be prompted to restart your KDK after an update. |
| `kdk.debug`                       | `false` | Set this to `true` to enable increased output. |
| `kdk.overwrite_changes`           | `false` | When set to `true`, `kdk reconfigure` overwrites files and move the old version to `.backups`.|
| `kdk.protected_config_files`      | `[]`    | Contains file names / globs of configuration files KDK should not overwrite. |
| `kdk.runit_wait_secs`             | `20`    | The number of seconds `runit` waits. `runit` is used behind the scenes for `kdk stop/start/restart`. |
| `kdk.auto_reconfigure`            | `true`  | Set this to `false` to not run a `kdk reconfigure` after a successful `kdk update`. |
| `kdk.auto_rebase_projects`        | `false` | Set this to `true` to automatically rebase projects as part of a `kdk update`. |
| `kdk.system_packages_opt_out`     | `false` | Set this to `true` if you don't want KDK to manage installation of system packages. |
| `kdk.preflight_checks_opt_out`    | `false` | Set this to `true` if you don't want KDK to check whether your [platform is supported](../README.md#supported-platforms). This setting is unsupported. |

##### Experimental KDK settings

Experimental settings may be promoted to stable settings or they may be deprecated.

| Setting | Default | Description |
|---------|---------|-------------|
| `kdk.experimental.auto_reconfigure` | `true`  | Set this to `true` to automatically run a `kdk reconfigure` after a successful `kdk update`. |

##### Hooks

Before and after hooks are supported for `kdk start`, `kdk stop`, and `kdk update`.

> [!note]
> Hooks are executed with the KDK root directory as the working directory. Execution halts if a command completes with a non-zero exit code.

| Setting                    | Default | Description                                                         |
|----------------------------|---------|---------------------------------------------------------------------|
| `kdk.start_hooks.before`   | `[]`    | Array of commands to be executed sequentially before `kdk start`.   |
| `kdk.start_hooks.after`    | `[]`    | Array of commands to be executed sequentially after `kdk start`.    |
| `kdk.stop_hooks.before`    | `[]`    | Array of commands to be executed sequentially before `kdk stop`.    |
| `kdk.stop_hooks.after`     | `[]`    | Array of commands to be executed sequentially after `kdk stop`.     |
| `kdk.update_hooks.before`  | `[]`    | Array of commands to be executed sequentially before `kdk update`.  |
| `kdk.update_hooks.after`   | `[]`    | Array of commands to be executed sequentially after `kdk update`.   |

> [!note]
> When running `kdk restart`, `kdk.stop_hooks` (both before & after) are executed before restarting and `kdk.start_hooks` (both before & after) are executed after restarting.

A common use for KDK hooks is
[removing uncommitted changes to `khulnasoft/db/structure.sql`](troubleshooting/postgresql.md#kdk-update-leaves-khulnasoftdb-with-uncommitted-changes),
or [truncating the Rails logs in `khulnasoft/log`](troubleshooting/ruby.md#truncate-rails-logs).

### KhulnaSoft settings

#### Rails

| Setting | Default | Description |
|---------|---------|-------------|
| `khulnasoft.cache_classes` | `false`  | Set this to `true` to disable the automatic reloading of Ruby classes when Ruby code is changed. |
| `khulnasoft.rails.hostname` | `127.0.0.1` | Specify the hostname value that Rails uses when generating URLs. |
| `khulnasoft.rails.port` | `3000` | Specify the port value that Rails uses when generating URLs. |
| `khulnasoft.rails.https.enabled` | `false` | Specify if HTTPS is enabled which Rails uses when generating URLs. |
| `khulnasoft.rails.address` | `''`     | Specify whether Rails should listen to a UNIX socket or a TCP port. Useful for debugging with Wireshark. Use `host:port` to listen on a TCP port. Do **not** include `http://`. |
| `khulnasoft.rails.multiple_databases` | `false` | Deprecated. Use `khulnasoft.rails.databases.ci` instead. Set this to `true` to configure [multiple database connections](https://docs.khulnasoft.com/ee/development/database/multiple_databases.html) in your `config/database.yml`. |
| `khulnasoft.rails.databases.ci.enabled` | `true` | Set this to `true` to configure [multiple database connections](https://docs.khulnasoft.com/ee/development/database/multiple_databases.html) in your `config/database.yml`. |
| `khulnasoft.rails.databases.ci.use_main_database` | `false` | When `true`, the CI database connection uses the same database as the main database (`khulnasofthq_development`). When `false`, it uses a distinct database (`khulnasofthq_development_ci`). Only relevant when `khulnasoft.rails.databases.ci.enabled` is enabled. |
| `khulnasoft.rails.databases.sec.enabled` | `false` | Set this to `true` to configure [multiple database connections](https://docs.khulnasoft.com/ee/development/database/multiple_databases.html) in your `config/database.yml`. |
| `khulnasoft.rails.databases.sec.use_main_database` | `true` | When `true`, the [`khulnasoft_sec` schema](https://docs.khulnasoft.com/ee/development/database/multiple_databases.html#khulnasoft-schema) uses the same database as the main database (`khulnasofthq_development`). When `false`, it uses a distinct database (`khulnasofthq_development_sec`). Only relevant when `khulnasoft.rails.databases.sec.enabled` is enabled. |
| `khulnasoft.rails.puma.workers` | `2` | Set this to `0` to prevent Puma (webserver) running in a [Clustered mode](https://github.com/puma/puma/blob/master/docs/architecture.md). Running in Single mode provides significant memory savings if you work within a [memory-constrained environment](https://khulnasoft.com/groups/khulnasoft-org/-/epics/5303). |
| `khulnasoft.rails.bootsnap` | `true` | Set this to `false` to disable [Bootsnap](https://github.com/Shopify/bootsnap). |
| `khulnasoft.rails.allowed_hosts` | `[]` | Allows Rails to serve requests from specified hosts, other than its KDK's host. Configure this setting to allow a Geo primary site to handle forwarded requests from a Geo secondary site using a different `hostname`. When this setting is configured, the hosts are also added to the `webpack.allowed_hosts` setting. Example value: `["kdk2.test"]`. |
| `khulnasoft.rails.application_settings_cache_seconds` | `60` | Sets the [application settings cache interval](https://docs.khulnasoft.com/ee/administration/application_settings_cache.html). Set to `0` to have changes take immediate effect, at the cost of loading the `application_settings` table for every request causing extra load on Redis and/or PostgreSQL. |

#### Rails background jobs (Sidekiq)

| Setting | Default | Description |
|---------|---------|-------------|
| `khulnasoft.rails_background_jobs.verbose` | `false`  | Set this to `true` to increase the level of logging Sidekiq produces. |
| `khulnasoft.rails_background_jobs.timeout` | `10`  | Set this to the number of seconds to ask Sidekiq to wait before forcibly terminating. |

### Skip compile

> [!note]
> The following settings are experimental and might change in the future.

For some software, it's possible to download the pre-compiled binaries instead of
compiling them.

| Setting | Default | Description |
|---------|---------|-------------|
| `workhorse.skip_compile` | `false` | Set this to `true` and download a Workhorse pre-compiled binary from the [package registry](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/packages). |
| `gitaly.skip_compile` | `false` | Set this to `true` and download a Gitaly pre-compiled binary from the [package registry](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/packages). |
| `khulnasoft_shell.skip_compile` | `false` | Set this to `true` and download a KhulnaSoft Shell pre-compiled binary from the [package registry](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/packages). |

### KhulnaSoft Docs settings

Under the `docs_khulnasoft_com` key, you can define the following settings:

| Setting                       | Default | Description |
|:------------------------------|:--------|:------------|
| `docs_khulnasoft_com.enabled`     | `false` | Set to `true` to enable [`docs-khulnasoft-com`](https://khulnasoft.com/khulnasoft-org/technical-writing/docs-khulnasoft-com) to be managed by KDK. |
| `docs_khulnasoft_com.auto_update` | `true`  | Set to `false` to disable updating the `docs-khulnasoft-com` checkout. |
| `docs_khulnasoft_com.port`        | `1313`  | The port for Hugo to listen on. |

For more information on using KhulnaSoft Docs with KDK, see the [KhulnaSoft Docs how to](howto/khulnasoft_docs.md).

### Snowplow Micro

Under the `snowplow_micro` key, you can define the following settings:

| Setting                      | Default                           | Description                                                                                              |
|:-----------------------------|:----------------------------------|:---------------------------------------------------------------------------------------------------------|
| `snowplow_micro.enabled`     | `false`                           | Set to `true` to enable [`snowplow-micro`](howto/snowplow_micro.md) to be managed by KDK.                                         |
| `snowplow_micro.image`       | `snowplow/snowplow-micro:latest`  | Docker image to run.                                                                                     |
| `snowplow_micro.port`        | `9091`                            | The port for `snowplow-micro` to listen on.                                                              |

### Additional projects settings

You can have KDK manage checkouts for these projects:

- `khulnasoft-runner`
- `khulnasoft-pages`
- `omnibus-khulnasoft`
- `charts/khulnasoft`
- `cloud-native/khulnasoft-operator`

Under the `khulnasoft_runner` key, you can define the following settings:

| Setting                      | Default | Description                                                                                                  |
|:-----------------------------|:--------|:-------------------------------------------------------------------------------------------------------------|
| `khulnasoft_runner.enabled`      | `false` | Set to `true` to enable [`khulnasoft-runner`](https://github.com/khulnasoft-lab/khulnasoft-runner) to be managed by KDK. |
| `khulnasoft_runner.auto_update`  | `true`  | Set to `false` to disable updating the `khulnasoft-runner` checkout.                                             |

Under the `khulnasoft_pages` key, you can define the following settings:

| Setting                                  | Default                          | Description                                                                                                 |
|:-----------------------------------------|:---------------------------------|:------------------------------------------------------------------------------------------------------------|
| `khulnasoft_pages.enabled`                   | `false`                          | Enable [`khulnasoft-pages`](https://github.com/khulnasoft-lab/khulnasoft-pages) to be managed by KDK.                   |
| `khulnasoft_pages.auto_update`               | `true`                           | Set to `false` to disable updating the `khulnasoft-pages` checkout.                                             |
| `khulnasoft_pages.host`                      | `127.0.0.1.nip.io`               | Set `khulnasoft-pages` host.                                                                                    |
| `khulnasoft_pages.port`                      | `3010`                           | Set `khulnasoft-pages` port.                                                                                    |
| `khulnasoft_pages.secret_file`               | `$KDK_ROOT/khulnasoft-pages-secret`  | Set `khulnasoft-pages` file that contains the secret to communicate in the internal API.                        |
| `khulnasoft_pages.verbose`                   | `false`                          | Set `khulnasoft-pages` verbose logging.                                                                         |
| `khulnasoft_pages.propagate_correlation_id`  | `false`                          | Set `khulnasoft-pages` to propagate the `correlation_id` received.                                              |
| `khulnasoft_pages.access_control`            | `false`                          | Enable `khulnasoft-pages` access control.                                                                       |
| `khulnasoft_pages.auth_client_id`            | `''`                             | The OAuth application ID used when access control is enabled.                                               |
| `khulnasoft_pages.auth_client_secret`        | `''`                             | The OAuth client secret used when access control is enabled.                                                |
| `khulnasoft_pages.auth_scope`                | `'api'`                          | The OAuth client scope used when access control is enabled.                                                 |
| `khulnasoft_pages.enable_custom_domains`     | `false`                          | Enable `khulnasoft-pages` custom domains.                                                                       |

For further details check the [Contribute to KhulnaSoft Pages development](https://docs.khulnasoft.com/ee/development/pages/) documentation.

Under the `omnibus_khulnasoft` key, you can define the following settings:

| Setting                       | Default | Description                                                                                                    |
|:------------------------------|:--------|:---------------------------------------------------------------------------------------------------------------|
| `omnibus_khulnasoft.enabled`      | `false` | Set to `true` to enable [`omnibus-khulnasoft`](https://khulnasoft.com/khulnasoft-org/omnibus-khulnasoft) to be managed by KDK. |
| `omnibus_khulnasoft.auto_update`  | `true`  | Set to `false` to disable updating the `omnibus-khulnasoft` checkout.                                              |

Under the `charts_khulnasoft` key, you can define the following settings:

| Setting                      | Default | Description                                                                                                  |
|:-----------------------------|:--------|:-------------------------------------------------------------------------------------------------------------|
| `charts_khulnasoft.enabled`      | `false` | Set to `true` to enable [`charts/khulnasoft`](https://khulnasoft.com/khulnasoft-org/charts/khulnasoft) to be managed by KDK. |
| `charts_khulnasoft.auto_update`  | `true`  | Set to `false` to disable updating the `charts/khulnasoft` checkout.                                             |

Under the `khulnasoft_operator` key, you can define the following settings:

| Setting                       | Default | Description                                                                                                                                |
|:------------------------------|:--------|:-------------------------------------------------------------------------------------------------------------------------------------------|
| `khulnasoft_operator.enabled`     | `false` | Set to `true` to enable [`cloud-native/khulnasoft-operator`](https://khulnasoft.com/khulnasoft-org/cloud-native/khulnasoft-operator) to be managed by KDK. |
| `khulnasoft_operator.auto_update` | `true`  | Set to `false` to disable updating the `cloud-native/khulnasoft-operator` checkout.                                                            |

### NGINX settings

| Setting | Default | Description |
|---------|---------|-------------|
| `nginx.enabled` | `false` | Set this to `true` to enable the `nginx` service. |
| `nginx.listen_address` | `127.0.0.1` | Set this to the IP for NGINX to listen on. |
| `nginx.bin` | `/usr/sbin/nginx` | Set this to the path to your `nginx` binary. |
| `nginx.ssl.certificate` | `localhost.crt` | This maps to [NGINX's `ssl_certificate`](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate). |
| `nginx.ssl.key` | `localhost.key` | This maps to [NGINX's `ssl_certificate_key`](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_certificate_key). |
| `nginx.http2.enabled` | `false` | Set this to `true` to enable HTTP/2 support. |

See [configuring NGINX](howto/nginx.md) for a comprehensive guide.

### Configuration precedence

KDK uses the following order of precedence when selecting the
configuration method to use:

- `kdk.yml`
- Default value

### Reading the configuration

To print settings from the configuration you can use `kdk config get <setting>`.

More information on the available `kdk` commands is found in [KDK commands](kdk_commands.md).

### Implementation detail

Here are some details on how the configuration management is built. You can
continue reading, or watch the [deep-dive](https://youtu.be/SFttPeywHf8)
recorded by [Toon](http://khulnasoft.com/toon).

#### KDK::ConfigSettings

This is the base class and the engine behind the configuration
management. It defines a DSL to configure KDK.

Most of the magic happens through the class method
`.method_missing`. The implementation of this method dynamically
defines instance methods for configuration settings.

Below is an example subclass of `KDK::ConfigSettings` to demonstrate
each kind.

```ruby
class ExampleConfig < KDK::ConfigSettings
  foo 'hello'
  bar { rand(1..10) }
  fuz do |f|
    f.buz 1234
  end
end
```

- `foo`: (literal value) This is just a literal value, it can be any
  type (for example, Number, Boolean, String).
- `bar`: (block without argument) This is using a block to set a
  value. It evaluates the Ruby code to dynamically calculate a value.
- `fuz`: (block with argument) When the block takes a single argument,
  it expects you are setting child settings.

If you'd dump this configuration with `rake dump_config`, you get something
like:

```yaml
foo: hello
bar: 5
fuz:
  buz: 1234
```

When you use a block without argument you can also calculate a value
based on another setting. So for example, we'd could replace the `bar`
block with `{ config.fuz.buz + 1000 }` and then the value would be
`2234`.

#### `KDK::Config`

`KDK::Config` is the single source of truth when it comes down to
defaults. In this file, every existing setting is specified and for
each setting a default is provided.

#### Dynamic settings

Some settings in `KDK::Config` are prepended with `__` (double
underscore). These are not supposed to be set in `kdk.yml` and only
act as a intermediate value. They also are not shown by `#dump!`.

### Adding a setting

When you add a new setting:

1. Add it to `lib/kdk/config.rb`.
1. Run `rake kdk.example.yml` to regenerate this file.
1. Commit both files.

## Runner settings

Under the runner key you can define the following settings for the [KhulnaSoft Runner](https://docs.khulnasoft.com/runner/):

| Setting | Default | Description |
| --- | ------ | ----- |
| `enabled` | `false` | Set this to `true` to enable the `runner` service. |
| `config_file` | `$KDK_ROOT/khulnasoft-runner-config.toml` | Path to your runner's `config.toml`. Defaults to KDK-managed config file. |
| `install_mode` | `binary` | Set this to `docker` in order to create a Docker container instead of using a local `khulnasoft-runner` binary. |
| `executor` | `docker` | Set this to `shell` if you want to use a shell executor. |
| `image` | `khulnasoft/khulnasoft-runner:latest` | Docker image to use for the runner when using `install_mode: docker`. |
| `docker_pull` | `always` | Docker pull option when running the runner Docker image. For available options, see [`docker run`](https://docs.docker.com/engine/reference/commandline/run/#pull) documentation. |
| `pull_policy` | `if-not-present` | Docker pull policy for the job image. |
| `bin` | `/usr/loca/bin/khulnasoft-runner` | Path to local runner binary when using `install_mode: binary`. |
| `extra_hosts` | `[]` | Sets the value of the `extra_hosts = []` key under `[runners.docker]` in the runner config. If using the Docker runner, these hosts are added to the container as `--add-host` flags. |
| `network_mode_host` | `false` | Set this to `true` to set `network_mode = "host"` for the `[runners.docker]` section (only on Linux). |
| `token` | Empty | Runner token to add to the runner config. |

## Vite settings

[Vite](https://vitejs.dev/) offers an improved developer experience by default.

Vite compiles JavaScript and Vue files quickly and only as requested.
Vite also consumes less memory.

These improvements are possible because Vite uses [esbuild](https://esbuild.github.io/) under the hood.
For more details on the implementation of Vite at KhulnaSoft, see the RFC [frontend/rfcs#106](https://khulnasoft.com/khulnasoft-org/frontend/rfcs/-/issues/106).

If you are using Vite, please [leave feedback](https://github.com/khulnasoft-lab/khulnasoft/-/issues/423851) of your experience.
There are some known caveats, they are linked to the feedback issue. Please make sure to check those. There are two caveats worth calling out:

1. `vite` serves files directly, so ad blockers might [block them based on their name](https://github.com/khulnasoft-lab/khulnasoft/-/issues/433361).
   The workaround is to turn ad blockers off for the KDK.
1. `vite` on Linux watches a lot of files, so you might need to raise the [max_watch_files](https://github.com/khulnasoft-lab/khulnasoft/-/issues/434329) limit.

To enable Vite for your KDK:

1. Ensure that your `kdk` is up to date (`kdk update`)
1. Ensure the `kdk` is running with webpack.
1. If you ran `vite` manually before, make sure no process remains.
1. Run the following commands to set up Vite:

      ```shell
      kdk stop webpack rails-web
      kdk config set webpack.enabled false
      kdk config set vite.enabled true
      kdk reconfigure
      kdk restart vite rails-web
      ```

To disable Vite, run the following commands:

```shell
kdk stop vite rails-web
kdk config set vite.enabled false
kdk config set webpack.enabled true
kdk reconfigure
kdk restart webpack rails-web
```

### Vite `kdk.yml` settings

| Setting   | Default | Description                                                                                                  |
|-----------|---------|--------------------------------------------------------------------------------------------------------------|
| `enabled` | `false` | Set to `true` to enable Vite.                                                                                |
| `port`    | `3038`  | The port your Vite development server is running on. You should change this if you are running multiple KDKs. |

## Webpack settings

The KDK ships with [`vite` support](#vite-settings). Consider trying it for a better developer experience.

### Webpack `kdk.yml` settings

Under the webpack key you can define the following settings with their defaults:

```yaml
webpack:
  enabled: true
  host: 127.0.0.1
  port: 3808
  static: false
  vendor_dll: false
  incremental: true
  incremental_ttl: 30
  allowed_hosts: []
```

| Setting | Default | Description |
| --- | ------ | ----- |
| `enabled` | `true` | Set to `false` to disable webpack. |
| `host` | `127.0.0.1` | The host your webpack development server is running on. Usually no need to change. |
| `port` | `3808` | The port your webpack development server is running on. You should change this if you are running multiple KDKs |
| `static` | `false` | Setting this to `true` replaces the webpack development server with a lightweight Ruby server with. See below for more information |
| `vendor_dll` | `false` | Setting this to `true` moves certain dependencies to a webpack DLL. See below for more information |
| `incremental` | `true` | Setting this to `false` disables incremental webpack compilation. See below for more information |
| `incremental_ttl` | `30` | Sets the number of days after which a visited page's assets will be evicted from the list of bundles to eagerly compile. Set to `0` to eagerly compile every page's assets ever visited. |
| `sourcemaps` | `true` | Setting this to `false` disables source maps. This reduces memory consumption for those who do not need to debug frontend code. |
| `live_reload` | `true` | Setting this to `false` disables hot module replacement when changes are detected. |
| `public_address` | | Allows to set a public address for webpack's live reloading feature. This setting is mainly utilized in GitPod, otherwise the address should be set correctly by default. |
| `allowed_hosts` | `[]` | Webpack can serve requests from hosts other than its KDK's host. Use this setting on a Geo primary site that serves requests forwarded by Geo secondary sites. Defaults to `khulnasoft.rails.allowed_hosts`. You don't usually need to set this for Webpack. Example value: `["kdk2.test"]`. |

#### Incremental webpack compilation

By default, webpack only compiles page bundles for pages that were visited
within the last `webpack.incremental_ttl` days. This is done to keep the memory
consumption of the webpack development server low. If you visit a previously
unvisited page or one visited longer than `webpack.incremental_ttl` days ago,
you see an overlay informing you that the page is being compiled. A page reload
(either manually or via `live_reload`) then ensures the correct assets are
served.

You can change the number of days that page bundles are considered "recent",
and should be eagerly compiled. This number represents the trade-off between
lazy/eager compilation versus low/high memory consumption of the webpack
development server. A higher number means fewer pages needing to be compiled on
demand, at the cost of higher memory consumption. A lower number means lower
memory consumption, at the cost of more pages being compiled on demand. A value
of `0` means that all pages in your history, regardless of how long ago you
visited them, are eagerly compiled.

For instance, if you visited a particular page `webpack.incremental_ttl - 1`
days ago, it would render as normal if you visited it _today_. But, if instead
you visit it _tomorrow_, you would see an initial "compiling" overlay.

The history of previously visited pages is stored in the `WEBPACK_CACHE_PATH`
directory. Clearing this directory will lose that history, meaning subsequent
page visits will trigger on demand compilation. Over time, your history will be
rebuilt.

To disable incremental compilation entirely and always eagerly compile all page
bundles, set `webpack.incremental: false` in your `kdk.yml`.

#### Saving memory on the webpack development server

KDK defaults to mostly memory-intensive settings. KDK uses the webpack development server, which watches
file changes and keeps all the frontend assets in memory. This allows for very fast recompilation.

An alternative is to lower the memory requirements of KDK. This is useful for back-end development
or where KDK is running in lower-memory environments. To lower the memory requirements of KDK:

- Set `webpack.static: true` in your `kdk.yml`. All frontend assets are compiled once when KDK starts
  and again from scratch if any front-end source or dependency file changes. For example, when
  switching branches.
- Set `webpack.vendor_dll: true` in your `kdk.yml`. This mode is an alternate memory saving mode,
  which takes infrequently updated dependencies and combines them into one long-lived bundle that is
  written to disk and does not reside in memory. You may see 200 to 300 MB in memory savings.
- Reduce the value of `webpack.incremental_ttl` in your `kdk.yml`. This means
  fewer page bundles will be eagerly compiled.

This means you pay a high upfront cost of a single memory- and CPU-intensive compile. However, if
you do not change any frontend files, you just have a lightweight Ruby server running.

If you experience any problems with one of the modes, you can quickly change the settings in your
`kdk.yml` and regenerate the `Procfile`:

```shell
kdk reconfigure
```

#### Webpack allowed hosts

By default, webpack only accepts requests with a `Host` header that matches the KDK `hostname`. This is a secure default. But sometimes you may
want webpack to accept requests from other known hosts.

The `webpack.allowed_hosts` setting takes an array of strings, for example `["kdk2.test", "kdk3.test"]`.

When `webpack.allowed_hosts` is not explicitly configured in `kdk.yml`, it defaults to `khulnasoft.rails.allowed_hosts`. In that case, the
configuration flow is:

```mermaid
graph LR
  A["kdk.yml<br>(khulnasoft.rails.allowed_hosts)"]

  subgraph Template
  B["khulnasoft.yml.erb<br>(khulnasoft.allowed_hosts)"]
  C["Procfile.erb<br>(DEV_SERVER_ALLOWED_HOSTS)"]
  end

  A --> B
  A --> C

  subgraph Generated
  D["khulnasoft.yml<br>(khulnasoft.allowed_hosts)"]
  E["Procfile<br>(DEV_SERVER_ALLOWED_HOSTS)"]
  end

  B -- kdk reconfigure --> D
  C --> E

  subgraph Runsv
  F[rails-web]
  G["webpack<br>(allowedHosts)"]
  end

  D -- kdk start --> F
  E --> G
```

##### Example

As an example:

- Your KDK `hostname` is `kdk.test`.
- You are running another KDK locally as a Geo secondary site with `hostname` set to `kdk2.test`.

As a result, web requests against `kdk2.test` reference webpack URLs for `kdk2.test` at the **same port** as the primary webpack. Web requests
are made to the same port because the Geo secondary site proxies most web requests to the primary site and so the primary site renders the
webpack links.

The `Host` of the original request is propagated to the primary site, and the primary site renders URLs with that `Host`. However, the primary
site has no way of knowing if the secondary site is running webpack at a different port. You can't run two webpack servers locally, listening on
the same port for different hosts.

So what options do you have to make this work? You can either:

- Run your `kdk2.test` site on a different IP.
- Let the `kdk2.test` webpack requests reach the primary site's webpack server. The requests would get blocked by default, and then you could
  unblock them with `webpack.allowed_hosts` setting.

  In this case, you would already set `khulnasoft.rails.allowed_hosts` to `["kdk2.test"]`. This is why `webpack.allowed_hosts` defaults to
  `khulnasoft.rails.allowed_hosts`.

### Webpack environment variables

The KhulnaSoft application exposes various configuration options for webpack via
environment variables. These can be modified to improve performance or enable debugging.

These settings can be configured using [`env.runit`](runit.md#modify-service-configuration).

<!-- markdownlint-disable MD044 -->

| Variable | Default | Description |
| ------------- | ------- | ----------- |
| DEV_SERVER_LIVERELOAD | true | Disables live reloading of frontend assets |
| NO_COMPRESSION        | false | Disables compression of assets |
| NO_SOURCEMAPS         | false | Disables generation of source maps (reduces size of `main.chunk.js` by ~50%) |
| WEBPACK_MEMORY_TEST   | false | Output the in-memory heap size upon compilation and exit |
| WEBPACK_CACHE_PATH    | `./tmp/cache` | Path string to temporary dir     |
| WEBPACK_REPORT        | false       | Generates bundle analysis report |
| WEBPACK_VENDOR_DLL    | false       | Reduce webpack-dev-server memory requirements when vendor bundle has been precompiled with `yarn webpack-vendor` |
| KHULNASOFT_UI_WATCH       | false | Use KDK's copy of `khulnasoft-ui` instead of the npm-installed version. |

<!-- markdownlint-enable MD044 -->

## ActionCable settings

Under the `action_cable` key you can define the following settings with their defaults:

```yaml
action_cable:
  worker_pool_size: 4
```

| Setting            | Default | Description |
|--------------------|---------|-------------|
| `worker_pool_size` | `4`     | Adjust this to control the number of ActionCable threads. This usually doesn't need to be changed. |

## Grafana settings

Under the `grafana` key you can define the following settings with their defaults:

```yaml
grafana:
  enabled: false
  port: 4000
```

| Setting   | Default | Description |
|-----------|---------|-------------|
| `enabled` | `false` | Set this to `true` to enable the `grafana` service. |
| `port`    | `4000`  | Set your preferred TCP port for the `grafana` service. |

## `asdf` settings

Under the `asdf` key you can define the following settings with their defaults:

```yaml
asdf:
  opt_out: false
```

| Setting   | Default | Description |
|-----------|---------|-------------|
| `opt_out` | `false` | Set this to `true` to tell KDK to _not_ use `asdf`, even if it's installed. |

## IDE settings

To get alias completion and type hinting in the `khulnasoft` project, you need to create a `jsconfig.json` file.
See [Type hinting aliases](https://docs.khulnasoft.com/ee/development/fe_guide/type_hinting.html#aliases).

## Environment variables

Temporary environment variables last only for the duration of your current shell and KDK session.
This is useful for testing or short-term changes:

1. Export environment variables in your shell:

   ```shell
   export <VARIABLE_NAME_1>=<VALUES_1>; export <VARIABLE_NAME_2>=<VALUES_2>; ...
   ```

1. Run `kdk restart`.

For environment variables to persist across sessions, you can use [`env.runit`](runit.md#using-environment-variables).
