---
title: .kdkrc.custom
---

The `<KDK_ROOT>/.kdkrc.custom` file allows customization of the KDK executing
environment by enhancing variables and logic defined in `<KDK_ROOT>/.kdkrc`.

Some examples of what you might need to add to `.kdkrc.custom` include:

- Customizing `LDFLAGS`, `CPPFLAGS` or `PKG_CONFIG_PATH` environment variables
- Setting an environment variable for an upcoming MR, e.g `export KHULNASOFT_NEW_FEATURE_X=1`

Changes to `.kdkrc.custom` are ignored by Git.
