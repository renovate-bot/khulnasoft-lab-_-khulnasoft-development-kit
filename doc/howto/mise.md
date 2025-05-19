---
title: Migrate to `mise` for dependency management
---

> [!important]
> As of **April 1st**, `mise` is default tool version manager for KDK. If
> you are still using `asdf`, please migrate to `mise` as soon as
> possible to avoid any disruptions to your workflow.

`mise` is the tool version manager used by KDK. It manages dependencies,
such as Ruby or Go, automatically for you. For every project, it reads a
`.tool-versions` (or `mise.toml`) file to download, install, and provide
these dependencies.

For example, if you run `bundle exec`, `mise` detects that project's Ruby
version based on the `.tool-versions` file and executes `bundle` in the
context of it. This ensures that different projects can use different
dependency versions without affecting your entire system or other
projects.

**Note:** `mise` is not compatible with `asdf` and vice versa. Do not use
both at the same time.

## How to migrate

To migrate to `mise`, follow these steps from your KDK directory:

1. Run the migration command:

   ```shell
   bundle exec rake mise:migrate
   ```

   This Rake task automatically:

   - Opts out of `asdf`
   - Enables `mise` support
   - Installs the new local hooks and dependencies
   - Re-bootstraps KDK

1. Reconfigure and update KDK.

   ```shell
   kdk reconfigure && kdk update
   ```

1. [Uninstall asdf](https://asdf-vm.com/manage/core.html#uninstall) if you're not using it outside of KDK.

## Troubleshooting

If you encounter problems with mise, see [the troubleshooting page](../troubleshooting/mise.md).
