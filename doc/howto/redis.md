---
title: Redis
---

Redis is the in-memory store used by the KhulnaSoft application. It can be run in
standalone, sentinel, and cluster mode.

## Using `custom_config`

The Redis setup in KDK is a standalone server. For local development, developers
can use `custom_config` to run KDK against a Redis server in sentinel or cluster
mode.

Update `kdk.yml` as seen in the format below to override KDK and use Redis's `custom_config` field. 
`environment` is either `development` or `test`. `instance` refers to the
functional shard type, for example, `cache`, `sessions`, etc.

The `body` is a string or hash compatible with [`redis-rb`](https://github.com/redis/redis-rb/tree/v4.8.0).

```yaml
redis:
  custom_config:
    <environment>:
      <instance>: <body>
```

For example, when working with another Redis setup in cluster mode, the
following config can be used:

```yaml
---
redis:
  custom_config:
    test:
      cache:
        cluster:
          - host: '127.0.0.1'
            port: 7001
          - host: '127.0.0.1'
            port: 7101
          - host: '127.0.0.1'
            port: 7201
    development:
      cache:
        cluster:
          - host: '127.0.0.1'
            port: 7001
          - host: '127.0.0.1'
            port: 7101
          - host: '127.0.0.1'
            port: 7201
```
