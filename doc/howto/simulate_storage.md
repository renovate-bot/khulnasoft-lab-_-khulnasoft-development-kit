---
title: Simulate slow or broken repository storage
---

## Simulating Broken Storage Devices

To test how KhulnaSoft behaves when the underlying storage system is not working
you can simply change your local KhulnaSoft instance to use an empty directory for
the repositories. To do so edit your `kdk.yml` configuration file so that the
`git_repositories` option points to an empty directory and run `kdk reconfigure`.

If you're running Linux, review the [Device mapper (Linux only)](#device-mapper-linux-only) section before you continue.

## Simulating Slow Filesystems

To simulate a slow filesystem you can use the script `bin/mount-flow-fs`. This
script can be used to mount a local directory via SSHFS and slow down access to
the files in this directory. For more information see
[mount-slow-fs](#mount-slow-fs).

## mount-slow-fs

This script can be used to mount a source directory at a given mount point via
SSHFS and slow down network traffic as a way of replicating a slow NFS. Usage of
this script is as following:

```shell
support/mount-slow-fs path/to/actual/repositories /path/to/mountpoint
```

As an example, we use the following directories:

- Source directory: `~/Projects/repositories`
- Mountpoint: `/mnt/repositories`

First create the mountpoint and set the correct permissions:

```shell
sudo mkdir /mnt/repositories
sudo chown $USER /mnt/repositories
```

Now we can run the script:

```shell
support/mount-slow-fs ~/Projects/repositories /mnt/repositories
```

Terminating the script (using ^C) automatically unmounts the repositories
and remove the created traffic shaping rules.

## Device Mapper (Linux only)

The Linux kernel's device mapper subsystem allows one to emulate slow and/or broken
filesystems via the `delay`, `flakey`, and `dust` targets to emulate
arbitrary read/write delays, intermittent I/O failures, and bad disk sectors. The
setup depends on the respective target and is documented in the kernel's
[admin guide](https://www.kernel.org/doc/html/latest/admin-guide/device-mapper/).

The following is an example to set up delayed disk writes. First we create a
disk image of 100MB size. You can adjust the size as required. While the disk
can be created anywhere you like, it is recommended to create it in your KDK
root directory.

```shell
cd <kdk-root>
dd if=/dev/zero of=disk.img bs=1M count=100
```

To make it available as block device, we use `losetup` and mount the image as
a loop device and create a filesystem on it:

```shell
sudo losetup -f disk.img
sudo mkfs.ext4 /dev/loop0
```

Next, we set up the `delay` target via device mapper. The following command
uses a delay of 250ms for reads and 500ms for writes. As before, you can simply
adjust these as required. Note that the final argument to dmsetup
(`kdk_delayed`) is the name of the created block device and can be adjusted
too.

```shell
echo "0 $(sudo blockdev --getsz /dev/loop0) delay /dev/loop0 0 250 /dev/loop0 0 500" |
    sudo dmsetup create kdk_delayed
```

We can now mount it:

```shell
sudo mount /dev/mapper/kdk_delayed /mnt/kdk_repositories
```

To make use of the delayed device, you need to configure Gitaly to use the mount
you have just set up. This can vary depending on your setup, but typically
requires adjusting `<kdk-root>/kdk.yml` to contain the following snippet:

```yaml
git_repositories:
  - "/mnt/kdk_repositories"
```
