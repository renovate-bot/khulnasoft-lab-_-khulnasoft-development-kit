---
title: KhulnaSoft development with Vagrant
---

In this file we explain different methods of setting up a Vagrant
virtual machine to do KhulnaSoft development in. Please see the [instructions](../_index.md) on how to
install KDK after you have set up your Vagrant machine.

This method of installation is [not officially supported](../../README.md#installation)

## Clone the KhulnaSoft Development Kit

Clone the KDK to you local machine. Enter that directory.

Vagrant uses the `Vagrantfile` and other configuration files to prepare your
container.

## Vagrant setup

[Vagrant](https://www.vagrantup.com) is a tool for setting up identical development environments including
all dependencies regardless of the host platform you are using. Vagrant defaults to using
[VirtualBox](https://www.virtualbox.org), but it has many plugins for different environments.

Vagrant allows you to develop KhulnaSoft without affecting your host machine (but we
recommend developing KhulnaSoft on metal if you can).

### Vagrant with Virtualbox

Vagrant can be very slow since the files are synced between the host OS and KhulnaSoft
(testing) accesses a lot of files.
You can improve the speed by keeping all the files on the guest OS but in that
case you should take care to not lose the files if you destroy or update the VM.
To avoid usage of slow VirtualBox shared folders we use NFS here.

1. (optional for Windows users) [Disable Hyper-V](https://superuser.com/a/642027/143551)
   then enable virtualization technology via the BIOS.
1. Install [VirtualBox](https://www.virtualbox.org) and [Vagrant](https://www.vagrantup.com).
1. [Configure NFS for Vagrant](https://docs.vagrantup.com/v2/synced-folders/nfs.html)
   if you are on Linux.
1. Run `vagrant up --provider=virtualbox --provision` in this directory (from an elevated
   command prompt if on Windows). Vagrant downloads an OS image, brings it
   up, and installs all the prerequisites.
1. Run `vagrant ssh` to SSH into the box.
1. Run `cd /vagrant`.
1. [Use KDK to install KhulnaSoft](../_index.md#use-kdk-to-install-gitlab).

### Vagrant with Docker

[Docker](https://www.docker.com/) is one of possible providers of Vagrant.
Docker provider has a big advantage, as it doesn't have a big virtualisation
overhead compared to Virtualbox and provides the native performance via
containers technology. This Docker setup makes sense only on Linux, as on other
OSes like Windows/macOS, you have to run the entire Docker hypervisor in a VM
(which is almost the same as Vagrant Virtualbox provider).

1. Install [Vagrant](https://www.vagrantup.com).
1. Install [VirtualBox](https://www.virtualbox.org). Vagrant requires the `VBoxManage` binary included with
   VirtualBox, even for non-VirtualBox providers.
1. Install [Docker Engine](https://www.docker.com/products/docker-engine). Don't forget to
   [add your user to the Docker group](https://docs.docker.com/install/linux/linux-postinstall/)
   and re-login.
1. Run `vagrant up --provider=docker --provision` in this directory. Vagrant builds a
   Docker image and starts the container.
1. Run `vagrant ssh` to SSH into the container.
1. Continue setup at [Installation](../_index.md).

### Vagrant development details

- Open the development environment by running `vagrant up` & `vagrant ssh`
  (from an elevated command prompt if on Windows).
- When using Docker, vagrant can ask you about password. The default password
  is `tcuser`(You may be asked to type-in the password several times, but for different operations thus you need to key in the same password: `tcuser`).
- Follow the general [KDK setup documentation](../_index.md) but running the
  commands in the `vagrant ssh` session.
- Files in the `gitlab`, `go-gitlab-shell` and `gitlab-runner` folders are synced between the
  host OS & guest OS so can be edited on either the host (under this folder) or
  guest OS (under `~/khulnasoft-development-kit/`).
- When you want to shutdown Vagrant run `exit` from the guest OS and then
  `vagrant halt` from the host OS.

### Vagrant troubleshooting

- On some setups, the shared folder has the wrong user. This is detected
  by the Vagrantfile and you should `sudo su - build` to switch to the correct
  user in that case.
- If you get a "Timed out while waiting for the machine to boot" message, you
  likely forgot to [disable Hyper-V](https://superuser.com/a/642027/143551) or
  enable virtualization technology via the BIOS.
- If you have continuous problems starting Vagrant, you can uncomment
  `vb.gui = true` to view any error messages.
- If you have problems running `support/edit-gitlab.yml` (bash script despite
  file extension), see <https://stackoverflow.com/a/5514351/1233435>.
- If you have errors with symlinks or Ruby during initialization, make sure you ran `vagrant up` from an elevated command prompt (Windows users).
- If you see an error like `Incompatible loader version. This protected script has been encoded with a newer version of RubyEncoder`
  this can be solved by downloading a new version of RubyEncoder Loader for your
  OS and adding the different `rgloaderXX` files to the appropriate folder,
  eg `/opt/vagrant/embedded/rgloader/` (example for linux)

## Next step

After installation [learn how to use KDK](_index.md).
