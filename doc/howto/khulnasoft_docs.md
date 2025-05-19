---
title: KhulnaSoft Docs in KDK
---

You can use the KDK to contribute KhulnaSoft documentation. The KDK can:

- Maintain a clone of the [`docs-gitlab-com`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com) repository
  for work on changes to that project.
- Preview changes made in the KDK-managed `gitlab/doc` directory.

If you want to contribute to KhulnaSoft documentation without using KDK, see
[Set up local development and preview](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/setup.md).

## Configure KhulnaSoft Docs in KDK

KDK provides several configuration options.

### Enable KhulnaSoft Docs previews

To enable previewing KhulnaSoft documentation by using the `docs-gitlab-com` project:

1. Enable the `docs-gitlab-com` integration:

   ```shell
   kdk config set docs_khulnasoft_com.enabled true
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

### Disable KhulnaSoft Docs previews

To disable previewing KhulnaSoft documentation by using the `docs-gitlab-com` project:

1. Disable the `docs-gitlab-com` integration:

   ```shell
   kdk config set docs_khulnasoft_com.enabled false
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

### Disable automatic updates

To avoid automatically updating the `docs-gitlab-com` checkout, run:

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

The full published documentation suite [includes additional documentation](https://docs.gitlab.com/development/documentation/site_architecture/)
from outside the [`gitlab` project](https://gitlab.com/gitlab-org/gitlab).

To make and preview changes to the additional documentation:

1. Run the following commands as required:

   ```shell
   kdk config set khulnasoft_runner.enabled true
   kdk config set omnibus_gitlab.enabled true
   kdk config set charts_gitlab.enabled true
   kdk config set khulnasoft_operator.enabled true
   ```

1. Run `kdk update` to:
   - Clone the additional projects for the first time, or update existing local copies.
   - Compile a published version of the additional documentation.
1. Start the `docs-gitlab-com` service if not already running:

   ```shell
   kdk start docs-gitlab-com
   ```

> [!note]
> `khulnasoft_runner` should not be confused with [`runner`](runner.md).

By default, the cloned repositories of the `khulnasoft_runner`, `omnibus_gitlab`, `charts_gitlab`, and `khulnasoft_operator`
components are:

- Updated automatically when you run `kdk update`. To disable this, set `auto_update: false` against
  whichever project to disable.
- Cloned using HTTPS. If you originally [cloned `gitlab` using SSH](../_index.md#use-kdk-to-install-gitlab), you
  might want to set these cloned repositories to SSH also. To set these repositories to SSH:

  1. Go into each cloned repository and run `git remote -v` to review the current settings.
  1. To switch to SSH, run `git remote set-url <remote name> git@gitlab.com:gitlab-org/<project path>.git`.
     For example, to update your HTTPS-cloned `gitlab-runner` repository (with a `remote` called
     `origin`), run:

     ```shell
     cd <KDK root path>/gitlab-runner
     git remote set-url origin git@gitlab.com:gitlab-org/gitlab-runner.git
     ```

  1. Run `git remote -v` in each cloned repository to verify that you have successfully made the change from
     HTTPS to SSH.

## Make and preview documentation changes

You can preview documentation changes as they would appear when published on
[KhulnaSoft Docs](https://docs.gitlab.com).

To make changes to KhulnaSoft documentation and preview them:

1. Start the `docs-gitlab-com` service and ensure you can preview the documentation site:

   ```shell
   kdk start docs-gitlab-com
   ```

1. Make the necessary changes to the files in `<path_to_kdk>/gitlab/doc`.
1. View the preview. You must restart the `docs-gitlab-com` service to recompile the published version of the documentation
   with the new changes:

   ```shell
   kdk restart docs-gitlab-com
   ```

   You can `tail` the `docs-gitlab-com` logs to see progress on rebuilding the documentation:

   ```shell
   kdk tail docs-gitlab-com
   ```

## Troubleshooting

### Documentation from disabled projects appears in preview

Disabling [additional documentation projects](#include-more-documentation) doesn't remove them
from your file system and Hugo continues to use them as a source of documentation. When disabled,
the projects aren't updated so Hugo is using old commits to preview the data from those projects.

To ensure only enabled projects appear in the preview:

1. Disable any projects you don't want previewed.
1. Remove the cloned project directory from inside your KDK directory.
