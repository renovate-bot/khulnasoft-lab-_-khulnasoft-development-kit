---
title: Troubleshooting mise
---

The following are possible solutions to problems you might encounter with
[mise](https://mise.jdx.dev/) and KDK.

If your issue is not listed here:

- For generic mise problems, raise an issue or pull request in the [mise project](https://github.com/jdx/mise).
- For KDK-specific issues, raise an issue or merge request in the [KDK project](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues).

If you are a KhulnaSoft team member, you can also ask for help with troubleshooting in
the `#mise` Slack channel. If your problem is KDK-specific, use the
`#kdk` channel so more people can see it.

## Error: `No such file or directory` when installing

You might have `mise install` fail with a cache error like the following.

```shell
$ mise install
mise ruby build tool update error: failed to update ruby-build: No such file or directory (os error 2)
mise failed to execute command: ~/Library/Caches/mise/ruby/ruby-build/bin/ruby-build 3.2.5 /Users/kdk/.local/share/mise/installs/ruby/3.2.5
mise No such file or directory (os error 2)
```

You can usually fix this by cleaning the mise cache: `mise cache clear`

## Error `~/.local/share/mise/plugins/yarn/bin/list-all: timed out: timed out waiting on channel`

If you use SSH to connect to GitHub, `yarn` might fail because of a timeout. You can temporarily use HTTPS by commenting out the following lines in `~/.gitconfig`:

```shell
#[url "git@github.com:"]
#    insteadof = https://github.com/
```

## Error: `command not found: kdk` or `mise is not activated`

Check steps in <https://mise.jdx.dev/getting-started.html#activate-mise> to ensure you have activated `mise` correctly.

If you use `zsh` than this should do the trick:

```shell
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
```

## Mise not reading default configuration file

In some cases, you may get into a situation where `mise` doesn't read/parse your existing config. In this state, `mise config` will return an empty list, despite your config being stored in a known config path (e.g. `~/.config/mise/config.toml`)

```shell
kdk@c2c644400e13:/khulnasoft-kdk$ mise config
Path  Tools
kdk@c2c644400e13:/khulnasoft-kdk$ ls ~/.config/mise/config.toml
/home/kdk/.config/mise/config.toml
```

This could be due to a previous command setting that config file to untrusted. To reverse this, you can execute `mise trust <file>` and it should resolve the issue.

```shell
kdk@c2c644400e13:/khulnasoft-kdk$ mise config
Path  Tools
kdk@c2c644400e13:/khulnasoft-kdk$ mise trust ~/.config/mise/config.toml
mise trusted /home/kdk
kdk@c2c644400e13:/khulnasoft-kdk$ mise config
Path                        Tools
~/.config/mise/config.toml  (none)
```

In some limited circumstances, this approach may not work. In that case, perhaps try following the troubleshooting in [this article](https://glenn-roberts.com/posts/2025/03/11/when-mise-ignores-your-global-config-a-tale-of-red-herrings-and-stale-state/).
