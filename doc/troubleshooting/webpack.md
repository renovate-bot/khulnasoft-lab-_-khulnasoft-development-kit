---
title: Troubleshooting Webpack
---

The KDK ships with [`vite` support](../configuration.md#vite-settings). Consider trying it for a better developer experience.

Since webpack has been added as a new background process which KhulnaSoft depends on
in development, the [KDK must be updated and reconfigured](../_index.md#update-kdk) in
order to work properly again.

If you still encounter some errors, see the troubleshooting FAQ below:

- I'm getting an error when I run `kdk reconfigure`:

  ```plaintext
  Makefile:30: recipe for target 'gitlab/config/gitlab.yml' failed
  make: *** [gitlab/config/gitlab.yml] Error 1
  ```

  This is likely because you have not updated your KhulnaSoft CE/EE repository to
  the latest default branch yet. It has a template for `gitlab.yml` in it which
  the KDK needs to update. The `kdk update` step should have taken care of this
  for you, but you can also manually go to your KhulnaSoft directory and run
  `git checkout main && git pull origin main`

    ---

- I'm getting an error when I attempt to access my local KhulnaSoft in a browser:

  ```plaintext
  Webpack::Rails::Manifest::ManifestLoadError at /
  Could not load manifest from webpack-dev-server at http://localhost:3808/assets/webpack/manifest.json - is it running, and is stats-webpack-plugin loaded?
  ```

  or

  ```plaintext
  Webpack::Rails::Manifest::ManifestLoadError at /
  Could not load compiled manifest from /path/to/khulnasoft-development-kit/khulnasoft/public/assets/webpack/manifest.json - have you run `rake webpack:compile`?
  ```

  This probably means that the webpack dev server isn't running or that your
  `gitlab.yml` isn't properly configured. Ensure that you have run
  `kdk reconfigure` **AND** `kdk restart webpack`.

  ---

- I see the following error when run `kdk tail` or `kdk tail webpack`:

  ```plaintext
  09:46:05 webpack.1               | npm ERR! argv "/usr/local/bin/node" "/usr/local/bin/npm" "run" "dev-server"
  09:46:05 webpack.1               | npm ERR! node v5.8.0
  09:46:05 webpack.1               | npm ERR! npm  v3.10.7
  09:46:05 webpack.1               |
  09:46:05 webpack.1               | npm ERR! missing script: dev-server
  ...
  ```

  This means your KhulnaSoft CE or EE instance is not running the current default
  branch. If you are running a branch which hasn't been rebased against the
  default branch since Saturday, Feb 4th then you should rebase it against the
  default branch. If you are running the default branch, ensure it is up to date
  with `git pull`.

  ---

- I see the following error when run `kdk tail` or `kdk tail webpack`:

  ```plaintext
  09:54:15 webpack.1               | > @ dev-server /Users/mike/Projects/khulnasoft-development-kit/khulnasoft
  09:54:15 webpack.1               | > webpack-dev-server --config config/webpack.config.js
  09:54:15 webpack.1               |
  09:54:15 webpack.1               | sh: webpack-dev-server: command not found
  09:54:15 webpack.1               |
  ...
  ```

  This means you have not run `yarn install` since updating your `gitlab/gitlab-foss`
  repository. The `kdk update` command should have done this for you, but you
  can do so manually as well.

  ---

- I see the following error when run `kdk tail` or `kdk tail webpack`:

  ```plaintext
  14:52:22 webpack.1               | [nodemon] starting `node ./node_modules/.bin/webpack-dev-server --config config/webpack.config.js`
  14:52:22 webpack.1               | events.js:160
  14:52:22 webpack.1               |       throw er; // Unhandled 'error' event
  14:52:22 webpack.1               |       ^
  14:52:22 webpack.1               |
  14:52:22 webpack.1               | Error: listen EADDRINUSE 127.0.0.1:3808
  ...
  ```

  This means the port is already in use, probably because webpack failed to
  terminate correctly when the KDK was last shutdown. You can find out the pid
  of the process using the port with the command `lsof -i :3808`. If you are
  using Vagrant the `lsof` command is not available. Instead you can use the
  command `ss -pntl 'sport = :3808'`. The left over process can be killed with
  the command `kill PID`.

  ---

- I see UI elements out of place when I access my local KhulnaSoft in a browser:

  This means your KDK has some stale CSS files that need to be removed. You can run `bundle exec rake assets:clean gitlab:assets:purge`
  to remove the contents of `public/assets/webpack`. Then run `kdk restart webpack` to trigger the regeneration of the files.
