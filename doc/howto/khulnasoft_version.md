---
title: KhulnaSoft version
---

Use the KDK to run a previous version of KhulnaSoft.

## Change the version

1. Find the [tag](https://github.com/khulnasoft-lab/khulnasoft/-/tags) or commit hash for the version of KhulnaSoft you want to use.
1. Navigate to the `/khulnasoft-development-kit/khulnasoft/` folder using the command line.
1. Switch to the target tag or commit hash and detach from `HEAD`:

   ```shell
   git switch <tag> --detach
   ```

    For example, `git switch v14.9.3-ee --detach` or `git switch 5087c814 --detach`.

1. Install and update dependencies:

   ```shell
   bundle install
   yarn install
   ```

1. Run database migrations:

   ```shell
   bundle exec rails db:migrate
   ```

1. Restart (or start) the KDK:

   ```shell
   kdk restart
   ```

   Always restart the KDK after performing database migrations to prevent deadlocks in components such as Sidekiq. The existing Rails process caches the
   database schema at boot, and may run on false assumptions until it reloads the database.

## Creating an alias

If this is an action you'll perform regularly consider creating the following alias:

```shell
kdkdowngradeto = !f() { git switch \"$1\" --detach && bundle exec rails db:migrate && bundle install && yarn install && kdk restart; }; f
```

Run the alias using `kdkdowngradeto v14.9.3-ee` or any other tag or commit hash.
