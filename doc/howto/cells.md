---
title: Cells
---

[[_TOC_]]

## KDK Cells numbering

When you set up Cells locally on KDK. `cells.instance_count` represents the number additional cells, in additional
to the Main cell, which did exist in all KDKs by default.

For example, if you set `cells.instance_count` to `2`. You get 3 total cells. They are represented
in this table.

| Cell ID | Other names             | Optional | Cell Default Database Sequence range |
|---------|-------------------------|----------|--------------------------------------|
| 1       | Primary / Legacy / Main | No       | [1, 9223372036854775807]             |
| 2       | Additional              | Yes      | [1 \* RANGE + 1, 2 \* RANGE]         |
| 3       | Additional              | Yes      | [2 \* RANGE + 1, 3 \* RANGE]         |

For `development` environment, this `RANGE` is equal to `1_000_000_000`.
For `production` environment, the legacy cell gets the `first trillion` IDs and new cells gets `100 billion` IDs each.

## Setting up cells locally

After setting up the main KDK instance, you can enable the additional cells using the following steps:

1. [Enable the HTTP router](#enabling-the-http-router)
1. Run `kdk start`
1. Run `kdk config set cells.enabled true`
1. Run `kdk config set cells.instance_count 1`
1. Run `kdk reconfigure`, this will restart `khulnasoft-topology-service` to include new cells config.
1. Run `kdk cells up` to install the cell instance to the
   `gitlab-cells/cell-2` directory and bootstrap the standard services.

   Every time after you change `cells.instance_count` or `cells.instances`
   in your `kdk.yml`, run `kdk reconfigure` and `kdk cells up` to set them up.
1. Run `kdk cells start` to start all cell instances:

   ```shell
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/postgresql: (pid 16197) 1s, normally down
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/redis: (pid 16213) 0s, normally down
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/praefect: (pid 16234) 1s, normally down
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/praefect-gitaly-0: (pid 16235) 1s, normally down
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/khulnasoft-http-router: (pid 16243) 0s, normally down
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/khulnasoft-workhorse: (pid 16244) 0s, normally down
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/rails-background-jobs: (pid 16245) 0s, normally down
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/rails-web: (pid 16247) 0s, normally down
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/sshd: (pid 16246) 0s, normally down
   ok: run: /path/to/kdk/gitlab-cells/cell-2/services/vite: (pid 16248) 0s, normally down

   => KhulnaSoft available at http://127.0.0.1:12001.
   =>   - Ruby: ruby 3.2.3 (2024-01-18 revision 52bb2ac0a6) [arm64-darwin23].
   =>   - Node.js: v20.12.2.
   => The HTTP Router is available at http://127.0.0.1:12001.
   ```

To access the cell instance, you can now visit the URL that's shown in
your terminal in your browser.

> [!warning]
> A cell inherits configuration from the main KDK, including any user-defined ports.
> This can lead to a port binding error for the cell’s workhorse, as it attempts to use the same port.
> The default port for the main KDK is 3000, which does not need to be explicitly specified.

### Adding a cell instance

After [setting up cells](#setting-up-cells-locally), you can add more cell
instances by increasing the `instance_count` in the configuration:

1. Run `kdk start` to start your main KDK instance, if not started already.
1. Run `kdk config set cells.instance_count 2` (or whatever
   `kdk config get cells.instance_count` returns plus 1)
1. Run `kdk reconfigure`
1. Run `kdk cells up`
1. Run `kdk cells start` to start all cell instances

### Updating cells

To update all cell instances, use `kdk cells update`.

Your main KDK instance stays untouched by this. Run `kdk update` to
update it separately.

### Overriding cell-specific configuration

The main KDK `kdk.yml` serves as the single source of truth. The command `kdk cells up` uses
this configuration to infer values and generate cell-specific configurations in the
`gitlab-cells/*/kdk.yml` files.

You should not manually modify generated cell configuration.

All configuration settings are inherited from main KDK configuration except for these settings:

- `cells.enabled`: disabled inside follower cells.
- `khulnasoft_http_router.enabled`: disabled inside follower cells.
- `khulnasoft_topology_service.enabled`: disabled inside follower cells.

To override a cell-specific configuration:

1. Apply the desired value in the main KDK `kdk.yml` file.
1. Run `kdk cells up`.

Here's an example config with cell-specific configuration being overridden:

1. Edit your main KDK `kdk.yml`:

   ```yaml
   cells:
     enabled: true
     instance_count: 1
     instances:
       config: # Only for cell-2
         gitlab:
           rails:
             session_store:
               session_cookie_token_prefix: abcd
   ```

1. Run `kdk cells up`.
1. Verify the cell configuration:

   ```shell
   kdk cells cell-2 config get gitlab.rails.session_store.session_cookie_token_prefix
   abcd
   ```

### Disabling cells

To temporarily disable cells without removing the cell instances from
your disk, follow these steps:

1. Run `kdk stop`
1. Run `kdk cells stop` to stop all cell instances
1. Run `kdk config set cells.enabled false`
1. Run `kdk reconfigure`
1. Run `kdk start`
1. Run `kdk cells up`
1. Optionally [disable the HTTP router](#enabling-the-http-router)

### Excluding the primary cell (cell-1) from the cluster

The primary cell (cell-1) is by default included in the cells cluster. That also means that all the session
cookies that are generated on this cell, have the prefix `cell-1`. This represents [Phase 6](https://gitlab.com/groups/gitlab-org/-/epics/14513)
in the roadmap
of releasing [Cells 1.0](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/iterations/cells-1.0/).
Which is when the legacy cell becomes part of the cluster.

But if for some reason it's needed to exclude the primary cell, to simulate prior phases (Phases 3 - 5), you can
follow the following steps.

1. Disable Topology service client for the primary cell by running `kdk config set gitlab.topology_service.enabled false`
1. Enable Topology service client for all the rest of cells in your primary `kdk.yml` by having something looks like this:
so your `kdk.yml` can look like this:

    ```yaml
    cells:
      enabled: true
      instance_count: 1
      instances:
      - config:
          gitlab:
            topology_service:
              enabled: true
    ```

    Overriding specific configuration in additional is explained in details in a previous section in this documentation file.

1. Run `kdk reconfigure` to reflect the changes for the primary cell.
1. Run `kdk cells up` to reflect the changes for the rest of cells.
1. Run `kdk restart`.
1. If you get an error when visiting the running KDK, try to clear existing cookies because they can interfere with the new cells settings.

### Removing cells permanently

To completely remove all local cell instances:

1. Run `kdk cells stop`
1. Run `kdk config set cells.enabled false`
1. Run `kdk reconfigure`
1. Delete the `gitlab-cells` folder
1. Optionally [disable the HTTP router](#enabling-the-http-router)

## Enabling the HTTP router

The [HTTP router](https://gitlab.com/gitlab-org/cells/http-router) is enabled
by default in KDK.

It sits in front of Workhorse, and [NGINX](nginx.md) (if enabled).

Refer to <https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/README.md> for details.

### Using the HTTP router

The router service supports HTTP and HTTPS.
`relative_url_root` is not supported.

By default, the HTTP router listens to the KDK port (which is by default
port `3000`). You can configure the router to use a distinct port with
the following commands:

```shell
kdk config set khulnasoft_http_router.use_distinct_port true
kdk config set khulnasoft_http_router.port 9393
```

#### Routing rules configuration

The Routing Service requires choosing a routing rule set. It supports the current rule sets:

1. `firstcell`
1. `passthrough`
1. `session_prefix` (default)
1. `session_token`

You can configure the router to use a different rule with the following commands:

```shell
kdk config set khulnasoft_http_router.khulnasoft_rules_config session_token
```

**note**: When using `session_prefix`, the `unique_cookie_key_postfix` variable must be set to `false` (default).

```shell
kdk config get gitlab.rails.session_store.unique_cookie_key_postfix # => should be false

# Otherwise, set it to false
kdk config set gitlab.rails.session_store.unique_cookie_key_postfix false
```

Refer to <https://gitlab.com/gitlab-org/cells/http-router/-/blob/main/docs/config.md#routing-rules> for details.

## Disabling the HTTP router

If for some reason you need to disable the HTTP router, then all the requests to the KDK will
go to the primary cell `cell-1`. You can also consider disabling the Topology Service, because
it won't be needed anymore.

To disable the HTTP router, run this script:

```shell
kdk config set khulnasoft_http_router.enabled false
kdk reconfigure
kdk restart
```

## Disabling the Topology Service

To disable the KhulnaSoft Topology Service, run this script:

```shell
kdk config set khulnasoft_topology_service.enabled false
kdk reconfigure
kdk restart
```

But in case you want to keep the HTTP router running, it's recommended to change its mode to `passthrough`.
Otherwise it might try to classify existing requests using the Topology Service which is not running anymore.
To do that, follow these steps:

```shell
kdk config set khulnasoft_http_router.khulnasoft_rules_config passthrough
kdk reconfigure
kdk restart
```

### Topology Service configuration

In the KhulnaSoft Rails app, the topology service is configured in the `config/gitlab.yml` file using
the KDK setting `gitlab.topology_service`.

If `khulnasoft_topology_service.enabled` is `true` and thus the Topology Service is enabled, then the
KDK configuration setting `gitlab.topology_service.*` will point by default to the Topology Service.

You can override the settings under `gitlab.topology_service` to point them to another Topology
Service. These settings are inherited by all the cells.
