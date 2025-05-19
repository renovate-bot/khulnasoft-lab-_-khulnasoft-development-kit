---
title: Git LFS
---

By default, Git LFS over HTTP is available in KDK without any extra configuration.

If you need to test Git LFS over SSH in KDK, you need run additional commands:

1. `kdk config set khulnasoft_shell.lfs.pure_ssh_protocol_enabled true`
1. `kdk reconfigure`
1. `kdk restart sshd`

These steps update the `lfs` section of your `<KDK_ROOT>/khulnasoft-shell/config.yml`
file to set the `pure_ssh_protocol` value to `true`:

```yaml
lfs:
  # See https://khulnasoft.com/groups/khulnasoft-org/-/epics/11872 for context
  pure_ssh_protocol: true
```

By default, the `git` and `git-lfs` clients do not display which protocol they are using. To check that you're using SSH:

1. Set the `GIT_TRACE` environment variable to `1`.
1. Perform a `git` operation on a repository with LFS enabled that is hosted in your KDK and you should see references to `pure SSH connection successful` in the output,
   which tells you the SSH protocol is being used.

   ```shell
   $ export GIT_TRACE=1
   $ git clone ssh://git@kdk.test:2222/root/lfs-project.git 2>&1 | grep 'pure SSH connection successful'
   16:40:36.545395 trace git-lfs: pure SSH connection successful
   16:40:36.735093 trace git-lfs: pure SSH connection successful
   ```
