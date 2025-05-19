---
title: Redis Cluster
---

Redis Cluster is Redis with cluster-mode enabled.

## Setup

The topology of the cluster is lightweight with 2 clusters (one for the development environment and one for the test environment) with 3 primary nodes each.

The nodes on the development environment run on ports `6000`, `6001`, and `6002` while the nodes on the test environment run on ports `6003`, `6004`, and `6005`.

## Enabling Redis Cluster

To use KDK with Redis Cluster, run the following commands:

```shell
kdk config set redis_cluster.enabled true
kdk reconfigure
```

This will update all relevant `gitlab/config/redis.*.yml` and initialise the `redis_cluster` service.

## Interacting with Redis Cluster nodes

Connect directly to the nodes via `redis-cli -p 600x` instead of `kdk redis-cli`.
