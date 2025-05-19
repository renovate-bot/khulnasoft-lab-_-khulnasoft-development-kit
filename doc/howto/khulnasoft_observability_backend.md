---
title: KhulnaSoft Observability Backend
---

Configure the KhulnaSoft Observability Backend (GOB) to run locally in KDK. This is required to ingest and query
observability signals metrics, logs, and traces. Using GOB in KDK will help you get up to speed quickly when developing these features.

Learn more about Observability for [tracing](https://docs.gitlab.com/ee/operations/tracing.html), [metrics](https://docs.gitlab.com/ee/operations/metrics.html) and [logs](https://docs.gitlab.com/ee/operations/logs.html) in our documentation.

## Prerequisites

- ClickHouse enabled in your KDK. [[Docs](https://docs.gitlab.com/ee/development/database/clickhouse/clickhouse_within_gitlab.html)]
- An EE Ultimate license in your KDK.
- KDK running as SaaS. [[Docs](https://docs.gitlab.com/ee/development/ee_features.html#simulate-a-saas-instance)]

## Get started

1. Enable the observability feature flag. `Feature.enable(:observability_features)`
1. Enable GOB in KDK by updating `kdk.yml` by running the following command. It is not enabled by default.

   ```shell
      kdk config set khulnasoft_observability_backend.enabled true
   ```

1. Set the required environment variables by adding the following lines to `<kdk_root>/env.runit`

   ```shell
   export OVERRIDE_OBSERVABILITY_QUERY_URL=http://localhost:9003
   export OVERRIDE_OBSERVABILITY_INGEST_URL=http://localhost:4318
   ```

1. Run `kdk reconfigure`.
1. Run `kdk start` to start the new service.

## Troubleshooting

### `gitlab-observability-backend` service not starting on macOS

After following the steps above you might find that `gitlab-observability-backend` is not able to start and returns the following message:

```shell
kdk status gitlab-observability-backend

down: /khulnasoft-development-kit/services/gitlab-observability-backend: 4s; run: log: (pid 93406) 5494s
```

In this case, check if the process can start at all by launching it manually:

```shell
cd gitlab/gitlab-observability-backend/go/cmd/all-in-one 
./all-in-one

./all-in-one [1] 19695 killed # the process is killed
```

If the process is killed right after starting, it might be due to issues with macOS code signing. To check if this is the case, run `codesign`:

```shell
codesign -vv all-in-one
all-in-one: invalid signature (code or signature have been modified)
In architecture: arm64
```

If an invalid signature is found, the process won't be able to start. 

Though it is not entirely clear why this happens (a proper fix TBD), in some cases it was because `go` was being managed by `asdf`.
See this [issue](https://github.com/golang/go/issues/63997) where other users faced a similar problem.

A workaround for this issue is to explicitly install or use a different `go` installation (for example via `homebrew` or [go.dev](https://go.dev/dl/)) and build the service with it.

```shell
brew install go

/opt/homebrew/bin/go build .

codesign -vv all-in-one
all-in-one: valid on disk
all-in-one: satisfies its Designated Requirement

./all-in-one

Error: get connection: getting database handle ... # process actually gets started now
```

At this point it should be possible to run `kdk start gitlab-observability-backend` successfully.

Note that every time you run `kdk update` or `kdk reconfigure`, you must manually rebuild the `gitlab-observability-backend`.
