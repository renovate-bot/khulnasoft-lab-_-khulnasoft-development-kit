---
title: KhulnaSoft Docs in KDK
---

You can use the KDK to contribute KhulnaSoft documentation. The KDK can:

- Maintain a clone of the [`docs-khulnasoft-com`](https://khulnasoft.com/khulnasoft-org/technical-writing/docs-khulnasoft-com) repository
  for work on changes to that project.
- Preview changes made in the KDK-managed `khulnasoft/doc` directory.

If you want to contribute to KhulnaSoft documentation without using KDK, see
[Set up local development and preview](https://khulnasoft.com/khulnasoft-org/technical-writing/docs-khulnasoft-com/-/blob/master/doc/setup.md).

## Configure KhulnaSoft Docs in KDK

KDK provides several configuration options.

### Enable KhulnaSoft Docs previews

To enable previewing KhulnaSoft documentation by using the `docs-khulnasoft-com` project:

1. Enable the `docs-khulnasoft-com` integration:

   ```shell
   kdk config set docs_khulnasoft_com.enabled true
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

### Disable KhulnaSoft Docs previews

To disable previewing KhulnaSoft documentation by using the `docs-khulnasoft-com` project:

1. Disable the `docs-khulnasoft-com` integration:

   ```shell
   kdk config set docs_khulnasoft_com.enabled false
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

### Disable automatic updates

To avoid automatically updating the `docs-khulnasoft-com` checkout, run:

```shell
kdk config set docs_khulnasoft_com.auto_update false
```

### Configure a custom port

The default port is `1313` but this can be customized:

```shell
kdk config set docs_khulnasoft_com.port 1314
```

### Configure HTTPS

You can run the KhulnaSoft Docs site using HTTPS. For more information, see [NGINX](nginx.md).

### Include more documentation

The full published documentation suite [includes additional documentation](https://docs.khulnasoft.com/development/documentation/site_architecture/)
from outside the [`khulnasoft` project](https://github.com/khulnasoft-lab/khulnasoft).

To make and preview changes to the additional documentation:

1. Run the following commands as required:

   ```shell
   kdk config set khulnasoft_runner.enabled true
   kdk config set omnibus_khulnasoft.enabled true
   kdk config set charts_khulnasoft.enabled true
   kdk config set khulnasoft_operator.enabled true
   ```

1. Run `kdk update` to:
   - Clone the additional projects for the first time, or update existing local copies.
   - Compile a published version of the additional documentation.
1. Start the `docs-khulnasoft-com` service if not already running:

   ```shell
   kdk start docs-khulnasoft-com
   ```

> [!note]
> `khulnasoft_runner` should not be confused with [`runner`](runner.md).

By default, the cloned repositories of the `khulnasoft_runner`, `omnibus_khulnasoft`, `charts_khulnasoft`, and `khulnasoft_operator`
components are:

- Updated automatically when you run `kdk update`. To disable this, set `auto_update: false` against
  whichever project to disable.
- Cloned using HTTPS. If you originally [cloned `khulnasoft` using SSH](../_index.md#use-kdk-to-install-khulnasoft), you
  might want to set these cloned repositories to SSH also. To set these repositories to SSH:

  1. Go into each cloned repository and run `git remote -v` to review the current settings.
  1. To switch to SSH, run `git remote set-url <remote name> git@khulnasoft.com:khulnasoft-org/<project path>.git`.
     For example, to update your HTTPS-cloned `khulnasoft-runner` repository (with a `remote` called
     `origin`), run:

     ```shell
     cd <KDK root path>/khulnasoft-runner
     git remote set-url origin git@khulnasoft.com:khulnasoft-org/khulnasoft-runner.git
     ```

  1. Run `git remote -v` in each cloned repository to verify that you have successfully made the change from
     HTTPS to SSH.

## Make and preview documentation changes

You can preview documentation changes as they would appear when published on
[KhulnaSoft Docs](https://docs.khulnasoft.com).

To make changes to KhulnaSoft documentation and preview them:

1. Start the `docs-khulnasoft-com` service and ensure you can preview the documentation site:

   ```shell
   kdk start docs-khulnasoft-com
   ```

1. Make the necessary changes to the files in `<path_to_kdk>/khulnasoft/doc`.
1. View the preview. You must restart the `docs-khulnasoft-com` service to recompile the published version of the documentation
   with the new changes:

   ```shell
   kdk restart docs-khulnasoft-com
   ```

   You can `tail` the `docs-khulnasoft-com` logs to see progress on rebuilding the documentation:

   ```shell
   kdk tail docs-khulnasoft-com
   ```

## Troubleshooting

### Documentation from disabled projects appears in preview

Disabling [additional documentation projects](#include-more-documentation) doesn't remove them
from your file system and Hugo continues to use them as a source of documentation. When disabled,
the projects aren't updated so Hugo is using old commits to preview the data from those projects.

To ensure only enabled projects appear in the preview:

1. Disable any projects you don't want previewed.
1. Remove the cloned project directory from inside your KDK directory.
