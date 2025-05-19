---
title: Mattermost
---

From the KDK directory, create [a `kdk.yml` configuration file](../configuration.md)
containing the following settings:

```yaml
mattermost:
  enabled: true
```

Then you just have to re-generate your Procfile by reconfiguring:

```shell
kdk reconfigure
```
