---
title: Elasticsearch
---

KhulnaSoft Enterprise Edition has Elasticsearch integration. In this
document we explain how to set this up in your development
environment.

## Installation

### Enable Elasticsearch in the KDK

The default version of Elasticsearch is automatically downloaded into your KDK root under `/elasticsearch`.

Elasticsearch is deployed with a minimum (`Xms`) and maximum (`Xmx`) [JVM Heap Size](https://www.elastic.co/guide/en/elasticsearch/reference/current//advanced-configuration.html#set-jvm-heap-size)
of 2GB. The options are defined in `<kdk root directory>/elasticsearch/config/jvm.options.d/custom.options`.

To enable the service and make it run as part of `kdk start`:

1. Run `kdk config set elasticsearch.enabled true`
1. Run `kdk reconfigure`.

### Using other search engines

#### Other versions of Elasticsearch

The default Elasticsearch version is defined in [`lib/kdk/config.rb`](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/master/lib/kdk/config.rb).

For example, to use 7.5.2:

1. Add the `version` and `[linux|mac]_checksum` keys to your [`kdk.yml`](../configuration.md):

   ```yaml
   elasticsearch:
     enabled: true
     version: 7.5.2
   ```

1. Install the selected version:

   ```shell
   make elasticsearch-setup
   ```

#### Opensearch

While KDK does not support installing OpenSearch, it can be easily run with Docker:

```shell
docker run --rm --name opensearch1.2.4 -p 9201:9200 -e "plugins.security.disabled=true" -e "discovery.type=single-node" opensearchproject/opensearch:1.2.4
```

## Setup

1. Go to **Admin Area > Subscription** and ensure you have a [license](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee) installed as this is required for Elasticsearch.

1. Start Elasticsearch by either running `elasticsearch` in a new terminal, or
   by starting the KDK service:

   ```shell
   kdk start elasticsearch
   ```

1. Perform a manual update of the Elasticsearch indexes:

   ```shell
   cd gitlab && bundle exec rake gitlab:elastic:index
   ```

1. Go to **Admin Area > Settings > Search > Advanced Search** to enable Elasticsearch.
1. Be sure to check the *Search with Elasticsearch enabled* checkbox.

## Tips and Tricks

### Query log

To enable logging for all queries against Elasticsearch you can change the slow
log settings to log every query. To do this you need to send a request to
Elasticsearch to change the settings for the `gitlab-development` index:

```shell
curl -H 'Content-Type: application/json' -XPUT "http://localhost:9200/gitlab-development/_settings" -d '{
"index.indexing.slowlog.threshold.index.debug" : "0s",
"index.search.slowlog.threshold.fetch.debug" : "0s",
"index.search.slowlog.threshold.query.debug" : "0s"
}'
```

After this you can see every query by tailing the logs from you KDK root:

```shell
tail -f elasticsearch/logs/elasticsearch_index_search_slowlog.log
```

### Rate limiting

The search endpoints are rate-limited and you might receive the following message:

`This endpoint has been requested too many times. Try again later.`

To increase the rate limiting for search requests, modify the
search rate limit in the admin settings.

1. Go to **Admin Area > Settings > Network**.
1. Expand **Search Rate Limit**.
1. Increase the **Maximum number of requests per minute for an authenticated user**.
1. Select **Save**.
