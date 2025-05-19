---
title: Troubleshooting Vite
---

The following are possible solutions to problems you might encounter with
[Vite](https://vitejs.dev/) and KDK.

## Error: `ViteRuby::MissingEntrypointError`

If your Node dependencies are missing or outdated, Vite might fail to find the required style files:

```shell
ViteRuby::MissingEntrypointError:
Vite Ruby can't find stylesheets/styles.emoji_sprites.scss in the manifests.

Possible causes:
  - The file path is incorrect.
  - The file is not in the entrypoints directory.
  - Some files are outside the sourceCodeDir, and have not been added to watchAdditionalPaths.
  - You have not run `bin/vite dev` to start Vite, or the dev server is not reachable.
  - "autoBuild" is set to `false` in your config/vite.json for this environment.

Visit the Troubleshooting guide for more information:
  https://vite-ruby.netlify.app/guide/troubleshooting.html#troubleshooting
```

To fix this run the following command from your KDK's root directory:

```shell
cd gitlab && yarn
```

If you still have issues, try running vite directly from a terminal, as that can show errors not
captured in logs. In the case motivating this suggestion, the UI showed the error above, and `log/vite/current`
showed:

```plaintext
2025-01-23_14:50:31.29582 vite                    : TypeError: Cannot read properties of undefined (reading 'join')
2025-01-23_14:50:31.29583 vite                    :     at file:///gitlab-kdk/khulnasoft-development-kit/khulnasoft/node_modules/vite/dist/node/chunks/dep-BJP6rrE_.js:18049:13
2025-01-23_14:50:31.29584 vite                    :     at async file:///gitlab-kdk/khulnasoft-development-kit/khulnasoft/node_modules/vite/dist/node/chunks/dep-BJP6rrE_.js:51643:28
```

The error in the log was also visible in a KDK that was working, so it was not the root cause.

To run vite in the terminal, run the followingrom your KDK's root directory:

```shell
kdk stop vite
cd gitlab && bundle exec bin/vite dev
```

## Error: ENOSPC

When running vite locally to debug issues, you may see this error:

```plaintext
node:internal/fs/watchers:247
    const error = new UVException({
                  ^

Error: ENOSPC: System limit for number of file watchers reached, watch '/gitlab-kdk/khulnasoft-development-kit/khulnasoft/app/assets/stylesheets/highlight/hljs.scss'
```

Especially when running the full KDK and editing the source with VS Code, the system is going to be creating a lot of inotify handles. The default
on your linux installation may not be enough to handle the load, which can cause vite to crash. Use the commands below to check your current limit,
and increase if necessary.

```shell
cat /proc/sys/fs/inotify/max_user_watches      # Check current value, e.g. 65536
sudo sysctl fs.inotify.max_user_watches=131070 # Write new value for immediate use
echo 'fs.inotify.max_user_watches=131072' |    # Persist change for future reboots
    sudo tee -a /etc/sysctl.d/local.conf
```
