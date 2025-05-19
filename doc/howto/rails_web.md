---
title: Rails Web
---

Rails Web is enabled by default.
If you don't want KDK to automatically start the Rails Web service:

1. Set `rails_web.enabled` to `false`:

   ```shell
   kdk config set rails_web.enabled false
   ```

1. Run `kdk reconfigure`
