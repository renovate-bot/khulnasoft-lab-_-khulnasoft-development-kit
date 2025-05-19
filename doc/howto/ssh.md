---
title: Configure and use SSH in KDK
---

KhulnaSoft can provide access to its repositories over SSH instead of HTTPS. There
are two ways to enable this in KDK. Either:

- Default. Run the [`khulnasoft-sshd`](https://docs.khulnasoft.com/ee/administration/operations/khulnasoft_sshd.html)
  binary provided by [KhulnaSoft Shell](https://github.com/khulnasoft-lab/khulnasoft-shell).
  Using `khulnasoft-sshd` is better for multi-host deployments like KhulnaSoft.com and
  development environments. By default, `khulnasoft-sshd` listens to port `2222`.
- Integrate KhulnaSoft Shell with [OpenSSH](https://openssh.org). Because integrating
  with OpenSSH allows KhulnaSoft to provide its services on the same port as the system's
  SSH daemon, this is the preferred option for most single-host deployments of KhulnaSoft.

KDK enables the first option by default. Only engineers working on the KhulnaSoft
OpenSSH integration need to use the second option.

## Change the listen port or other configuration

Copy lines into your `<kdk-root>/kdk.yml` file from `<kdk-root>/kdk.example.yml`,
and adjust as needed. For example, to change the listen port from the default `2222` to `2223`:

1. Add the following to your `<kdk-root>/kdk.yml` file:

   ```yaml
   ---
   sshd:
     listen_port: 2223
   ```

1. Run `kdk reconfigure` to configure the `sshd` service.

1. Run `kdk restart` to restart the modified services.

Note that some settings apply:

- Only to OpenSSH mode:
  - `additional_config`
  - `authorized_keys_file`
  - `bin`
- Only to `khulnasoft-sshd` mode:
  - `proxy_protocol`
  - `web_listen`

To switch from `khulnasoft-sshd` to OpenSSH, follow the
instructions under [OpenSSH integration](#openssh-integration).

### Optional: Use privileged port

On UNIX-like systems, only root users can bind to ports up to `1024`. If want KDK to run SSH
on, for example, port `22`, you can provide it the necessary privileges with the following
command:

```shell
sudo setcap 'cap_net_bind_service=+ep' khulnasoft-shell/bin/khulnasoft-sshd
```

## OpenSSH integration

In general, we recommend that you use `khulnasoft-sshd`. If you want to work on the
KhulnaSoft OpenSSH integration specifically, you can switch to it:

1. Add the following to your `<kdk-root>/kdk.yml` file:

   ```yaml
   ---
   sshd:
     use_khulnasoft_sshd: false
   ```

1. Run `kdk reconfigure` to switch from `khulnasoft-sshd` to OpenSSH.

1. Run `kdk restart` to restart the modified services.

You should now have an unprivileged OpenSSH daemon process running on
`127.0.0.1:2222`, integrated with `khulnasoft-shell`.

In unprivileged mode, OpenSSH can't change users, so you'll have to connect to
it using your system username, rather than `git`. The Rails web interface will
list the correct username whenever it gives you an example command, but you may
have to use `git remote set-url` in any repositories you have already cloned
from the instance to update them.

### SSH key lookup from database

For more information, see the
[official documentation](https://docs.khulnasoft.com/ee/administration/operations/speed_up_ssh.html#the-solution).
The `khulnasoft-sshd` approach uses SSH key lookup from database automatically, but
when using OpenSSH instead, a few more steps are required.

We'll create a wrapper script to invoke
`<kdk-root>/khulnasoft-shell/bin/khulnasoft-shell-authorized-keys-check`. This wrapper is useful
because the file invoked by `AuthorizedKeysCommand`, and all of its parent directories,
*must* be owned by `root`. We'll place the wrapper script in `/opt/khulnasoft-shell` as an
example, but it can be placed in any directory which is owned by `root` and whose parent
directories are also owned by `root`.

1. Create a file at `/opt/khulnasoft-shell/wrap-authorized-keys-check` with the following
   contents, making sure to replace `<kdk-root>` with the actual path:

   ```shell
   #!/bin/bash

   <kdk-root>/khulnasoft-shell/bin/khulnasoft-shell-authorized-keys-check "$@"
   ```

1. Make the script owned by root:

   ```shell
   sudo chown root /opt/khulnasoft-shell/wrap-authorized-keys-check
   ```

1. Make the script executable:

   ```shell
   sudo chmod 755 /opt/khulnasoft-shell/wrap-authorized-keys-check
   ```

1. Make OpenSSH check for authorized keys using `wrap-authorized-keys-check`. Add the
   following configuration in your `<kdk-root>/kdk.yml` file:

   ```yaml
   ---
   sshd:
     enabled: true
     additional_config: |
       Match User <KDK user> # Apply the AuthorizedKeysCommands to the git user only
         AuthorizedKeysCommand /opt/khulnasoft-shell/wrap-authorized-keys-check <KDK user> %u %k
         AuthorizedKeysCommandUser <KDK user>
       Match all # End match, settings apply to all users again
   ```

   `KDK user` should be the user that is running your KDK. This is probably your local
   username. You can double check this by looking in
   `<kdk-root>/khulnasoft/config/khulnasoft.yml` for the value of `development.khulnasoft.user`
   (or `production.khulnasoft.user`), or check which username is returned by
   `Project.first.ssh_url_to_repo`.

## Add an entry to `~/.ssh/config`

Prerequisites:

- You [set up `kdk.test`](local_network.md) to be the hostname of your KDK.
- You have [created and added an SSH key](https://docs.khulnasoft.com/ee/user/ssh.html) to your account.

The following example entry of `~/.ssh/config` uses the default KDK SSH port (`2222`):

```plaintext
Host kdk.test
  User git
  Hostname kdk.test
  Port 2222
  PreferredAuthentications publickey
  IdentityFile <path to SSH key>
```

After you add the entry,
[verify that you can connect](https://docs.khulnasoft.com/ee/user/ssh.html#verify-that-you-can-connect).

## Try it out

You can check that SSH works by visiting KhulnaSoft and cloning any project
using the Git protocol.

Alternatively, you can find the SSH URL of the first project by using the
[Rails console](rails_console.md) and use that to clone the repository:

```ruby
Project.first.ssh_url_to_repo
```

After you clone a project, your `known_hosts` file is also updated.
