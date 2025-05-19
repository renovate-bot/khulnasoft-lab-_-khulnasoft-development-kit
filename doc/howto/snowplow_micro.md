---
title: Snowplow Micro
---

You can use KDK to run Snowplow Micro collector.

## Enable Snowplow Micro

To enable KDK to manage `snowplow-micro`:

1. Ensure [Docker is installed and working](https://www.docker.com/get-started).

1. Enable Snowplow Micro:

   ```shell
   kdk config set snowplow_micro.enabled true
   ```

1. Optional. Snowplow Micro runs on port `9091` by default, you can change to `9092` by running:

   ```shell
   kdk config set snowplow_micro.port 9092
   ```

1. Regenerate your Procfile and YAML config by reconfiguring KDK:

   ```shell
   kdk reconfigure
   ```

1. Restart the KDK:

   ```shell
   kdk restart
   ```

1. Use these URLs to access Snowplow Micro:

   - `http://localhost:9091/micro/good`: View the good events.
   - `http://localhost:9091/micro/bad`: View the bad events .
   - `http://localhost:9091/micro/all`: View the statistics for all events.
   - `http://localhost:9091/micro/reset`: Reset the counter.
