---
title: Troubleshooting asdf
---

The following are possible solutions to problems you might encounter with [`asdf`](https://asdf-vm.com) and KDK.

> [!important]
> `asdf` will have reduced support and [`mise` will be the new default tool version manager](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/1683). You should
> [migrate to `mise`](../howto/mise.md) as soon as possible.

## KDK update fails to find the `asdf` path

KDK update might fail at the "Updating asdf release, plugins, and tools" step

```plaintext
--------------------------------------------------------------------------------
Updating asdf release, plugins, and tools
--------------------------------------------------------------------------------
Unknown command: `asdf version`
/usr/local/Cellar/asdf/0.10.2/libexec/bin/asdf: line 82: /usr/local/Cellar/asdf/0.8.1_1/libexec/lib/commands/command-help.bash: No such file or directory
INFO: asdf installed using non-Git method. Attempt to update asdf skipped.
Unknown command: `asdf plugin-update --all`
/usr/local/Cellar/asdf/0.10.2/libexec/bin/asdf: line 82: /usr/local/Cellar/asdf/0.8.1_1/libexec/lib/commands/command-help.bash: No such file or directory
Unknown command: `asdf install`
/usr/local/Cellar/asdf/0.10.2/libexec/bin/asdf: line 82: /usr/local/Cellar/asdf/0.8.1_1/libexec/lib/commands/command-help.bash: No such file or directory

ERROR: Failed to update some asdf tools.
❌️ ERROR: Failed to update.
```

This happens when `asdf` is updated to a new version during the KDK update. The `asdf reshim` command not updating the `asdf`
path is a [known issue](https://github.com/asdf-vm/asdf/issues/531).

To fix this, you can run the following command:

```shell
rm -rf ~/.asdf/shims && asdf reshim
```

## KDK update fails with `No preset version installed for command` error

KDK update might fail if `asdf` cannot locate a software version that is already installed.

```shell
No preset version installed for command go
Please install a version by running one of the following:

asdf install golang 1.21.2

or add one of the following versions in your config file at /Users/foo/khulnasoft-development-kit/khulnasoft/workhorse/.tool-versions
golang 1.20.10
golang 1.20.9
golang 1.21.3
make[2]: *** [gitlab-resize-image] Error 126
make[1]: *** [gitlab/workhorse/khulnasoft-workhorse] Error 2
make: *** [khulnasoft-workhorse-update-timed] Error 2
❌️ ERROR: Failed to update.
```

To resolve this, you can run the following command to uninstall and reinstall the version:

```shell
asdf uninstall golang 1.21.2 && asdf install golang 1.21.2
```

## Error: `command not found: kdk`

Access to the `kdk` command requires a properly configured Ruby installation. If the Ruby installation isn't properly
configured, your shell can't find the `kdk` command, and running commands like `kdk install` and `kdk start`
cause the following error:

```shell
command not found: kdk
```

A common cause of this error is an incomplete `asdf` setup. To determine if `asdf` setup is complete, run:

```shell
which asdf
```

### If `which asdf` returns  `asdf not found`

Then the `asdf` setup isn't complete. This often happens when installing KDK on new workstations without a custom shell configuration. 

A common solution is to follow the [`asdf` install instructions](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf) for your operating system and preferred method of installing `asdf`. 

- For macOS, it's common to use `Zsh shell & Git` or `Zsh shell & Homebrew` if you prefer to use [homebrew](https://brew.sh/) for managing your packages.
- You can use `echo $SHELL` to check which shell your workstation's using.

### If you know `asdf` is installed

Then it's likely `asdf` isn't sourced properly. Try these troubleshooting ideas:

- Close and open a new shell.
- If you're on a new workstation, confirm you have a shell configuration file. 
  - On MacOS it's a hidden file located in your home directory. Navigate to your home folder with `cd ~` (or `⇧⌘H` in the finder) and then reveal hidden files with `ls -a` (or `⇧⌘.` in the finder). 
  - If you don't see a shell config file (e.g. `.zshrc`) you can create one (e.g `touch .zshrc`) and then redo the above `asdf` install instructions.
- Confirm your shell config file matches the [`asdf` instructions](https://asdf-vm.com/guide/getting-started.html#_3-install-asdf) for your chosen shell and install method.
  - For example, if you're using MacOS with Zsh and Homebrew then you could source `asdf` by adding `. /opt/homebrew/opt/asdf/libexec/asdf.sh` in the `.zshrc` file.
  - Double check your shell config file has the correct sourcing command. Some `asdf` instructions give you commands to copy and paste into the config file, while others are added indirectly after you run the command in your terminal. For example, in the `Zsh & Homebrew` instructions `echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ${ZDOTDIR:-~}/.zshrc` should be run by you in your terminal and not copy and pasted into `.zshrc`.

## Conflicts with `mise`

If you're using [`mise`](../howto/mise.md), but you still have `asdf` installed,
you might see errors like the following:

```plaintext
Compiling gitlab/workhorse/khulnasoft-workhorse
# sync/atomic
compiler version "go1.22.5" does not match go tool version "go1.23.0"
make[3]: *** [gitlab-resize-image] Error 1
make[2]: *** [gitlab/workhorse/khulnasoft-workhorse] Error 2
make[1]: *** [khulnasoft-workhorse-setup] Error 2
make: *** [khulnasoft-workhorse-update-timed] Error 2
```

To solve this, uninstall one of the two dependency managers.

If that still doesn't work, you can try and [download pre-compiled binaries](../configuration.md#skip-compile) of
the software in question.
