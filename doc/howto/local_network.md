---
title: Local network binding
---

- `kdk.test` is the standard hostname for referring to the local KDK instance.
- `registry.test` is the standard hostname for referring to a local [container registry](registry.md).

We recommend [mapping these to a loopback interface](#create-loopback-interface) because it's more flexible, but they can also be mapped to `127.0.0.1`.

## Local interface

To set up `kdk.test` and `registry.test` as hostnames using `127.0.0.1`:

1. Add the following to the end of `/etc/hosts` (you must use `sudo` to save the changes):

   ```plaintext
   127.0.0.1 kdk.test registry.test
   ```

1. Set `hostname` to `kdk.test`:

   ```shell
   kdk config set hostname kdk.test
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

1. Restart KDK to use the new configuration:

   ```shell
   kdk restart
   ```

## Create loopback interface

Some functionality may not work if KDK processes listen on `localhost` or `127.0.0.1` (for example,
services [running under Docker](runner.md#executing-a-runner-from-within-docker)). Therefore, an IP address on a different private network should be
used.

`172.16.123.1` is a useful [private network address](https://en.wikipedia.org/wiki/Private_network#Private_IPv4_addresses)
that can avoid clashes with `localhost` and `127.0.0.1`.

To set up `kdk.test` and `registry.test` as hostnames using `172.16.123.1`:

1. Create an internal interface.

   For macOS, create an alias to the loopback adapter:

   ```shell
   sudo ifconfig lo0 alias 172.16.123.1
   ```

   For Linux, create a dummy interface:

   ```shell
   sudo ip link add dummy0 type dummy
   sudo ip address add 172.16.123.1 dev dummy0
   sudo ip link set dummy0 up
   ```

1. Add the following to the end of `/etc/hosts` (you must use `sudo` to save the changes):

   ```plaintext
   172.16.123.1 kdk.test registry.test
   ```

Make sure you remove previous entries for `kdk.test`, otherwise the hosts file will respect the first entry.

1. Set `hostname` to `kdk.test`:

   ```shell
   kdk config set hostname kdk.test
   ```

1. Set `listen_address` to `172.16.123.1`:

   ```shell
   kdk config set listen_address 172.16.123.1
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

1. Restart KDK to use the new configuration:

   ```shell
   kdk restart
   ```

1. Optional. Make the loopback alias [persist across reboots](#create-loopback-device-on-startup).

### Create loopback device on startup

For the loopback alias to work across reboots, the aliased IP address must be setup upon system boot.

#### macOS

To automate this on macOS, create a file called `org.khulnasoft1.ifconfig.plist` at `/Library/LaunchDaemons/` containing:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.khulnasoft1.ifconfig</string>
    <key>RunAtLoad</key>
    <true/>
    <key>Nice</key>
    <integer>10</integer>
    <key>ProgramArguments</key>
    <array>
      <string>/sbin/ifconfig</string>
      <string>lo0</string>
      <string>alias</string>
      <string>172.16.123.1</string>
    </array>
</dict>
</plist>
```

Ensure the created file has the correct permissions:

```shell
sudo chown root:wheel /Library/LaunchDaemons/org.khulnasoft1.ifconfig.plist
sudo chmod 644 /Library/LaunchDaemons/org.khulnasoft1.ifconfig.plist
```

#### Linux

The method to persist this dummy interface on Linux varies between distributions.

##### Ubuntu

On Ubuntu, you can run:

```shell
sudo nmcli connection add type dummy ifname dummy0 ip4 172.16.123.1
```
