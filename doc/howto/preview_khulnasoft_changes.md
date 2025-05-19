---
title: Preview KhulnaSoft changes
---

KDK is a common way to do KhulnaSoft development. It provides all the necessary structure to run KhulnaSoft
locally with code changes to preview the result. This provides:

- A fast feedback loop, because you don't need to wait for a KhulnaSoft Review App to be deployed to
  preview changes.
- Lower costs, because you can run KhulnaSoft and tests locally, without incurring the
  costs associated with running pipelines in the cloud.

These instructions explain how to preview user-facing changes, not how to do KhulnaSoft
development.

## Prepare KDK for previewing

To prepare KDK for previewing KDK changes:

1. Go to your KDK directory:

   ```shell
   cd <kdk-dir>
   ```

1. [Update](../kdk_commands.md#update-kdk) and [start](../kdk_commands.md#start-kdk-and-basic-commands) KDK. This ensures your
   KDK environment is close to the environment the changes:
   - Were made in, if you are previewing someone else's changes.
   - Are to be made in, if you are making your own changes.
1. Go to your local KhulnaSoft in your web browser and sign in (by default, [`http://localhost:3000`](http://localhost:3000)).
   Verify that KhulnaSoft runs properly.
1. Verify the current behavior of the feature affected by the changes. For Enterprise Edition
   features, you may need to [perform additional tasks](../_index.md#use-gitlab-enterprise-features).

## Make changes to KhulnaSoft

The process for applying changes to KhulnaSoft depends on whether you are:

- Making the changes yourself. When making your own changes, install and run:
  - [Front-end linting tools](https://docs.gitlab.com/ee/development/fe_guide/tooling.html)
    when making front-end changes.
  - [Lefthook](https://docs.gitlab.com/ee/development/contributing/style_guides.html#pre-commit-static-analysis)
    when making back-end changes.
- Previewing someone else's changes.

To make your own changes:

1. Go to your `gitlab` directory, throw away any changes KDK made when updating that left your
   checkout unclean, and switch to a new `gitlab` project branch:

   ```shell
   cd <kdk-dir>/gitlab
   git checkout -- .
   git checkout -b <your branch name>
   ```

1. Make the necessary changes within the `gitlab` directory.

To apply changes someone else made:

1. Switch to the branch containing the changes. The easiest way to do this is to:
   1. Go to the MR with the submitted changes.
   1. From the **Overview** tab, click the [**Check out branch** button](https://docs.gitlab.com/ee/user/project/merge_requests/index.html#merge-request-navigation-tabs-at-the-top).
      This displays a procedure.
   1. Copy the commands from **Step 1.** of the procedure. This adds to the clipboard all the
      commands required to switch to the branch locally.
   1. Go to your local `gitlab` directory and check you're on a clean checkout of `master`:

      ```shell
      git status
      ```

      You can discard any modifications caused by `kdk update` by running `git checkout -- .`.

   1. Paste the contents of the clipboard into your command line window and run them (for example, press enter). Your `gitlab` project
      branch should now be the branch containing the changes you want to preview. Confirm by
      running:

      ```shell
      git status
      git log
      ```

## Enable or disable KhulnaSoft feature flags

Some work-in-progress features are introduced behind [feature flags](https://docs.gitlab.com/ee/development/feature_flags/index.html).
To preview features behind disabled flags, you need to first enable the appropriate flag.

To enable a feature flag in your KDK instance:

1. [Start the Rails console](rails_console.md).
1. [Enable or disable desired flags](https://docs.gitlab.com/ee/administration/feature_flags.html#enable-or-disable-the-feature).
1. Exit the Rails console by running `quit`.

## Preview changes

After the changes are applied to KhulnaSoft:

1. Go to KhulnaSoft in your web browser to preview your changes (by default, [`http://localhost:3000`](http://localhost:3000)).
   It might be necessary to refresh the page, or even restart KDK:

   ```shell
   cd <kdk-dir>
   kdk restart
   ```

1. If previewing your changes, when you are satisfied with your changes and want to submit them for
   review, follow the process for submitting a merge request for a `gitlab` branch from the command
   line.
1. Once the work is completed, we recommend [updating KDK](../kdk_commands.md#update-kdk) again. This means that the
   next time you want to run it, KDK is based on the default branch for KhulnaSoft and not on the changed branch.
