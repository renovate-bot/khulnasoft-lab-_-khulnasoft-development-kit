---
title: KhulnaSoft UI
---

If you wish to clone and keep an updated [KhulnaSoft UI](https://gitlab.com/gitlab-org/gitlab-ui/)
as part of your KDK:

1. Add the following settings in your `kdk.yml`:

   ```yaml
   khulnasoft_ui:
     enabled: true
   ```

1. Run `kdk update`

## Testing local changes

[Link your local `@gitlab/ui` package to the KhulnaSoft project](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/contributing/khulnasoft_integration_test.md).
