---
title: Advanced dependency instructions
---

The following are dependency installation instructions for systems other than
those covered in the [main dependency installation instructions](_index.md#install-prerequisites).

These instructions may contain advanced configuration options that
[may not be officially supported](../README.md#installation).

## macOS

KDK supports macOS 10.14 (Mojave) and later. To install dependencies for macOS:

1. [Install](https://brew.sh) Homebrew to get access to the `brew` command for package management.
1. Clone the [`khulnasoft-development-kit` project](https://github.com/khulnasoft-lab/khulnasoft-development-kit) to `kdk`
   so you have access to the project's
   [`Brewfile`](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/Brewfile).
   You can:
     - Reuse an existing checkout if you have one, but make sure it's up to date.
     - Use this check out again when you [use KDK to install KhulnaSoft](_index.md#use-kdk-to-install-gitlab).

1. Install [`nvm`](https://github.com/nvm-sh/nvm#installing-and-updating). It should automatically
   configure it for your shell.
1. Install [the KDK required version of node](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/.tool-versions) using `nvm`, such as:

   ```shell
   nvm install 18.16.0
   ```

1. In the `kdk` checkout, run the following `brew` commands:

   ```shell
   brew bundle
   brew install go postgresql@12 minio/stable/minio rbenv redis yarn
   ```

   1. Add `$(brew --prefix)/opt/postgresql@12/bin` to your shell's `PATH` environment variable. For example, for macOS default `zsh` shell:

      ```shell
      export PATH="$(brew --prefix)/opt/postgresql@12/bin:$PATH"
      ```

1. [Configure `rbenv`](https://github.com/rbenv/rbenv#homebrew-on-macos) for your shell.
1. Install [the KDK required version of Ruby](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/.ruby-version)
using rbenv, such as:

   ```shell
   rbenv install 2.7.5
   ```

## Ubuntu and Debian

The following are instructions for Ubuntu and Debian users that don't want
[KDK to manage their dependencies](_index.md#install-dependencies).

These instructions help you install dependencies for Ubuntu, assuming you're using an active
LTS release (16.04, 18.04, 20.04, 22.04) or higher, and Debian:

1. [Install `git` and `make`](_index.md#install-prerequisites).
1. Clone the `khulnasoft-development-kit` repository into your preferred location, if you haven't previously:

   ```shell
   git clone https://github.com/khulnasoft-lab/khulnasoft-development-kit.git kdk
   ```

1. Change to the KDK project directory:

   ```shell
   cd kdk
   ```

1. Install NodeJS and Yarn.
   1. Check the required versions of NodeJS in the [`.tool-versions`](../.tool-versions) file.
   1. Install any of the required versions of NodeJS [using one of the installation methods](https://nodejs.org/en/download/package-manager/), for example by using the `nodesource` repository or `nvm`. The following example uses `nvm`:
      1. Install [`nvm`](https://github.com/nvm-sh/nvm#installing-and-updating). This should automatically configure it for your shell as well.
      1. Install the required version by using `nvm`:

         ```shell
         nvm install <NODEJS_VERSION>
         ```

   1. Install Yarn by using `npm`:

      ```shell
      npm install --global yarn
      ```

1. Run `make bootstrap-packages`. This is a light subset of `make bootstrap` that runs
   `apt-get update` and then `apt-get install` on the packages found in [`packages_debian.txt`](../packages_debian.txt).

   ```shell
   make bootstrap-packages
   ```

   - Check that `make bootstrap-packages` installed `redis-server` version 5.0 or later (`apt list
   redis-server`). Install [Redis](https://redis.io) 5.0 or later manually, if you don't already have
   it.

1. Install PostgreSQL.
   1. Check the required _major_ versions of PostgreSQL in the [`.tool-versions`](../.tool-versions) file.
      - Installation methods for PostgreSQL are typically limited to the latest _major_ version. When you select the version of PostgreSQL to install, you should only select the _major_ version. For example, if the [`.tool-versions`](../.tool-versions) file lists PostgreSQL version 13.6, install the latest version of PostgreSQL 13.
   1. Install the selected _major_ version of PostgreSQL by using its official repository - [Debian](https://www.postgresql.org/download/linux/debian/), [Ubuntu](https://www.postgresql.org/download/linux/ubuntu/).

1. Install MinIO.

   ```shell
   sudo curl "https://dl.min.io/server/minio/release/linux-amd64/minio" --output /usr/local/bin/minio
   sudo chmod +x /usr/local/bin/minio
   ```

1. Install Go.
   1. Check the required versions of Go in the [`.tool-versions`](../.tool-versions) file.
   1. Install any of the required versions of Go via the official instructions:
      1. [Download the correct Go package](https://go.dev/dl/) for your machine.
      1. [Install the package](https://go.dev/doc/install).
   1. Alternative methods of installing Go are available, for example [goenv](https://github.com/syndbg/goenv). You can use these if the version is correct and the Go binary is available on the PATH.

1. Install Ruby.
   1. Check the required versions of Ruby in the [`.tool-versions`](../.tool-versions) file.
   1. Install any of the required versions of Ruby [using one of the installation methods](https://www.ruby-lang.org/en/documentation/installation/), for example `rbenv` or `RVM`. The following example uses `rbenv`:
      1. Install [`rbenv`](https://github.com/rbenv/rbenv#using-package-managers).
      1. Install the [`ruby-build` plugin](https://github.com/rbenv/ruby-build#installation).
      1. Install the required version of Ruby via `rbenv`:

         ```shell
         rbenv install <RUBY_VERSION>
         ```

      1. A [`.ruby-version`](../.ruby-version) file is provided in the KDK for convenience. When Ruby has been installed via a manager like `rbenv` it [follows what's given in this file](https://github.com/rbenv/rbenv#choosing-the-ruby-version). If you've installed a supported version that differs from the one given in this file you should update it accordingly in your checkout before installing KDK.

1. Reload your chosen shell to ensure everything is picked up, for example with `bash`:

   ```shell
   source ~/.bashrc
   ```

1. Complete the rest of the [manual instructions](_index.md#install-dependencies-manually), then
   [use KDK to install KhulnaSoft](_index.md#use-kdk-to-install-gitlab).

## Install dependencies for other Linux distributions

The process for installing dependencies on Linux depends on your Linux distribution.

Unless already set, you might have to increase the watches limit of
`inotify` for frontend development tools such as `webpack` to effectively track
file changes. See [Inotify Watches Limit](https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit)
for details and instructions about how to apply this change.

### Arch and Manjaro Linux

The following are instructions for Arch and Manjaro users that don't want
[KDK to manage their dependencies with `mise`](_index.md#install-dependencies).
These steps should also work for other
[Arch-based distribution](https://wiki.archlinux.org/index.php/Arch-based_distributions) that use systemd.

To install dependencies for Arch Linux:

1. [Install `git` and `make`](_index.md#arch-and-manjaro-linux)

1. In the root of the `kdk` directory, run:

   ```shell
   sudo pacman -S $(sed -e 's/#.*//' packages_arch.txt)
   ```

1. [Install runit-systemd](#install-runit-on-arch-and-manjaro-linux).

#### Install runit on Arch and Manjaro Linux

The Arch Linux core repository no longer contains the `runit` package. You must
install [`runit-systemd`](https://aur.archlinux.org/packages/runit-systemd/) from the Arch User Repository (AUR).

If you're installing dependencies with [`mise`](_index.md#install-dependencies), `runit-systemd` is
installed as part of the `make bootstrap` command.

You can use an [AUR package helper](https://wiki.archlinux.org/index.php/AUR_helpers):

- For `pacaur` ([https://github.com/E5ten/pacaur](https://github.com/E5ten/pacaur)):

  ```shell
  pacaur -S runit-systemd
  ```

- For `pikaur` ([https://github.com/actionless/pikaur](https://github.com/actionless/pikaur)):

  ```shell
  pikaur -S runit-systemd
  ```

- For [`yay`](https://github.com/Jguer/yay):

  ```shell
  yay -S runit-systemd
  ```

### Fedora

> [!note]
> These instructions don't account for using `mise` for managing some dependencies.

We assume you are using Fedora >= 31.

> [!note]
> Fedora 32 ships PostgreSQL 11.x and Fedora 32+ ships PostgreSQL 12.x in default repositories.
> You can use `postgresql:11` or `postgresql:12` module to install PostgreSQL 11 or 12.
> But keep in mind that replaces the default version of PostgreSQL package, so you cannot
> use both versions at once.

```shell
sudo dnf module enable postgresql:12 # or postgresql:11
```

To install dependencies for Fedora:

```shell
sudo dnf install postgresql postgresql-libs redis libicu-devel \
  git git-lfs ed make cmake rpm-build gcc-c++ krb5-devel go postgresql-server \
  postgresql-contrib postgresql-devel GraphicsMagick sqlite-devel \
  perl-Digest-SHA perl-Image-ExifTool rsync libyaml-devel
sudo curl "https://dl.min.io/server/minio/release/linux-amd64/minio" --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
```

You may have to install Redis 5.0 or newer manually.

#### runit

You also have to install [runit](http://smarden.org/runit) manually.

Although the following instructions work for runit version 2.1.2, be sure to
read the up-to-date installation instructions on [the website](http://smarden.org/runit)
before continuing.

1. Download and extract the runit source code to a local folder to compile it:

   ```shell
   wget http://smarden.org/runit/runit-2.1.2.tar.gz
   tar xzf runit-2.1.2.tar.gz
   cd admin/runit-2.1.2
   sed -i -E 's/ -static$//g' src/Makefile
   ./package/compile
   ./package/check
   ```

1. Ensure all binaries in `command/` are accessible from your `PATH` (for
   example, symlink / copy them to `/usr/local/bin`)

### CentOS

> [!note]
> These instructions don't account for using `mise` for managing some dependencies.

We assume you are using CentOS >= 8.

To install dependencies for CentOS (tested on CentOS 8.2):

```shell
sudo dnf module enable postgresql:12
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf install postgresql-server postgresql-devel libicu-devel git git-lfs cmake \
  gcc-c++ go redis ed fontconfig freetype libfreetype.so.6 libfontconfig.so.1 \
  libstdc++.so.6 npm GraphicsMagick perl-Image-ExifTool \
  rsync sqlite-devel make
sudo curl "https://dl.min.io/server/minio/release/linux-amd64/minio" --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio

# This example uses Ruby 2.7.5. Substitute with the current version if different.
sudo rvm install 2.7.5
sudo rvm use 2.7.5
#Ensure your user is in rvm group
sudo usermod -a -G rvm <username>
#add iptables exceptions, or sudo service stop iptables
```

Follow [runit install instruction](#runit) to install it manually.

### Red Hat Enterprise Linux

> [!note]
> These instructions don't account for using `mise` for managing some dependencies, and
> were tested on RHEL 8.3.

To install dependencies for RHEL:

```shell
sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf module install postgresql:12 redis:5 nodejs:14 go-toolset
sudo dnf install postgresql-server postgresql-devel libicu-devel git git-lfs cmake \
  gcc-c++ go redis ed fontconfig freetype libfreetype.so.6 libfontconfig.so.1 \
  libstdc++.so.6 npm GraphicsMagick perl-Image-ExifTool \
  rsync sqlite-devel make
sudo curl "https://dl.min.io/server/minio/release/linux-amd64/minio" --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio

# This example uses Ruby 2.7.5. Substitute with the current version if different.
sudo rvm install 2.7.5
sudo rvm use 2.7.5
#Ensure your user is in rvm group
sudo usermod -a -G rvm <username>
#add iptables exceptions, or sudo service stop iptables
```

Follow [runit install instruction](#runit) to install it manually.

> [!note]
> Although RHEL8 has a FIPS-compliant mode and KhulnaSoft can be installed with it
> enabled, KhulnaSoft is not FIPS-compliant and doesn't run correctly with it
> enabled. [Epic &5104](https://gitlab.com/groups/gitlab-org/-/epics/5104) tracks
> the status of KhulnaSoft FIPS compliance.

### OpenSUSE

> [!note]
> These instructions don't account for using `mise` for managing some dependencies.

This was tested on `openSUSE Tumbleweed (20200628)`.

> [!note]
> OpenSUSE LEAP is currently not supported, because since a8e2f74d PostgreSQL 11+
> is required, but `LEAP 15.1` includes PostgreSQL 10 only.

To install dependencies for OpenSUSE:

```shell
sudo zypper dup
# now reboot with "sudo init 6" if zypper reports:
# There are running programs which still use files and libraries deleted or updated by recent upgrades.
sudo zypper install libxslt-devel postgresql postgresql-devel redis libicu-devel git git-lfs ed cmake \
        rpm-build gcc-c++ krb5-devel postgresql-server postgresql-contrib \
        libxml2-devel libxml2-devel-32bit findutils-locate GraphicsMagick \
        exiftool rsync sqlite3-devel postgresql-server-devel \
        libgpg-error-devel libqgpgme-devel yarn curl wget
sudo curl "https://dl.min.io/server/minio/release/linux-amd64/minio" --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
```

Install `go` manually using [Go](https://golang.org/doc/install) official installation instructions, for example:

```shell
curl -O "https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz"
sudo tar xpzf go1.14.4.linux-amd64.tar.gz -C /usr/local
```

Ensure that `node` has write permissions to install packages using:

```shell
mkdir -p ~/mynode/bin ~/mynode/lib
npm config set prefix ~/mynode
```

Install `runit` (it is no longer included in OpenSUSE):

```shell
wget http://smarden.org/runit/runit-2.1.2.tar.gz
tar xzf runit-2.1.2.tar.gz
cd admin/runit-2.1.2
sed -i -E 's/ -static$//g' src/Makefile
./package/compile
./package/check
sudo ./package/install
```

Set up local Ruby 2.7 environment, for example using [RVM](https://rvm.io/):

```shell
curl -sSL -o setup_rvm.sh "https://get.rvm.io"
chmod a+rx setup_rvm.sh
./setup_rvm.sh
source  /home/ansible/.rvm/scripts/rvm
rvm install 2.7.5
```

Append these lines to your `~/.bashrc`:

```shell
# to find binaries installed by yarn command
export PATH="$HOME/.yarn/bin:$PATH"
# to find sshd and redis-server in default path
export PATH="$PATH:/usr/sbin"
# to find go
export PATH="$HOME/go/bin:/usr/local/go/bin:$PATH"
# local node packages
export PATH="$HOME/mynode/bin:$PATH"
# KDK is confused with OSTYPE=linux (suse default)
export OSTYPE=linux-gnu
```

And reload it using:

```shell
source ~/.bashrc
```

Now determine that the current Ruby version is 2.7.x:

```shell
ruby --version
ruby 2.7.5p203 (2021-11-24 revision f69aeb8314) [x86_64-linux]
```

If it's different (for example Ruby 2.7 - system default in Tumbleweed), you
must sign in again.

The following `bundle config` option is recommended before you run
`kdk install` to avoid problems with the embedded library inside `gpgme`:

```shell
bundle config build.gpgme --use-system-libraries
```

Now you can proceed to [set up KDK](_index.md).

### Void Linux

To run KDK on Void, you must install `ruby` with development headers, gem binary dependencies, `go`,
`postgresql` with client, development headers and shared libraries, `sqlite`, `redis`:

```shell
sudo xbps-install -Su
sudo xbps-install ruby ruby-devel minio icu icu-libs icu-devel \
  go redis yarn GraphicsMagick sqlite sqlite-devel  pkg-config \
  postgresql13 postgresql13-client postgresql13-contrib postgresql-libs postgresql-libs-devel \
  meson ninja
```

### Gentoo Linux

This platform is not officially supported, but it is supported by wider community members.

The following are instructions for Gentoo users who don't want
[KDK to manage their dependencies with `mise`](_index.md#install-dependencies).

Install the required packages:

```shell
sudo emerge --noreplace app-admin/sudo app-arch/unzip app-crypt/gnupg app-crypt/mit-krb5 dev-build/meson dev-build/ninja dev-db/postgresql dev-db/redis dev-db/sqlite dev-lang/go dev-libs/icu dev-libs/libpcre2 dev-libs/libyaml dev-libs/openssl dev-python/docutils dev-util/cmake dev-util/pkgconf dev-util/yamllint dev-vcs/git dev-vcs/git-lfs media-gfx/graphicsmagick media-libs/exiftool net-libs/nodejs net-misc/curl net-misc/wget sys-apps/ed sys-apps/net-tools sys-apps/which sys-apps/yarn sys-apps/util-linux sys-libs/readline sys-libs/zlib sys-process/psmisc sys-process/runit virtual/openssh
```

Read the result message from emerge, as it will tell you what you must run
to configure PostgreSQL. It will be something like this:

```shell
sudo emerge --config dev-db/postgresql:15
```

Start the newly installed services:

```shell
sudo /etc/init.d/postgresql-15 start
sudo /etc/init.d/redis start

# And maybe you want to start them automatically on boot:
sudo rc-update add postgresql-15 default
sudo rc-update add redis default
```

Manually install `minio`, because it's not in Portage:

```shell
sudo curl "https://dl.min.io/server/minio/release/linux-amd64/minio" --output /usr/local/bin/minio
sudo chmod +x /usr/local/bin/minio
```

For bundler to work with system Ruby without trying to install gems in
system directory, you need to set the `GEM_HOME` variable. You can find
your user Gem install path with `gem env`. The value you're after is in the
`GEM_PATHS` list. You also need to add the `bin/` subdirectory from that
path to your `PATH` variable, in order to be able to call Ruby commands. So,
you should end up with something like the following in your shell config
(`~/.bashrc`, `~/.zshrc`, etc.):

```shell
export GEM_HOME=$HOME/.gem/ruby/3.1.0
export PATH="$GEM_HOME/bin/:$PATH"
```

If you're not familiar with using Ruby on Gentoo, note that several
versions can coexist on your system, and you must use the `eselect` command
to select which one you want to use. Frequently, during an update of minor
version (for example, going from Ruby 3.0 to Ruby 3.1), the Gem path will change, so
you will have to update `GEM_HOME` and install gems again running `bundle
install` in the Ruby projects.

Now you can proceed to [set up KDK](_index.md).

## Install FreeBSD dependencies

To install dependencies for FreeBSD:

```shell
sudo pkg install postgresql10-server postgresql10-contrib \
redis go node icu krb5 gmake re2 GraphicsMagick p5-Image-ExifTool git-lfs minio sqlite3
```

## Windows 10/Windows 11

You can set up KDK on Windows by using the Windows Subsystem for Linux (version 2 only).

Once WSL is set up, you can follow the same instructions for your Linux system. See [supported platforms](../README.md#supported-platforms).

The prerequisites for WSL, and the use of `mise` to manage dependencies, are the same as for any other Linux installation.

**Setting up the Windows Subsystem for Linux:**

Open PowerShell as Administrator and run:

```shell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
wsl --set-default-version 2
```

Restart your computer when prompted.

Install your Linux distribution of choice using the Windows Store. The available
distribution options include:

- Ubuntu
- OpenSUSE
- SLES
- Kali Linux
- Debian GNU/Linux

We have validated that Ubuntu 20.04 works correctly, but other distributions may also work.

Launch the distribution of choice.

You must ensure that your Linux distribution uses WSL version 2. Open PowerShell
with administrator privileges, and then run the following:

```shell
# If the command below does not return a list of your installed distributions,
# you have WS1.
wsl -l
```

You can [upgrade](https://docs.microsoft.com/en-us/windows/wsl/wsl2-kernel) your
WSL.

If you noticed your distribution of choice is an older subsystem, you can
upgrade it by running:

```shell
# Get the name of your subsystem
wsl -l
# Run the following command
wsl --set-version <your subsystem name here> 2
```

You might need to increase your memory allocation. See [Performance](#performance).

### Known issues with Windows Subsystem for Linux

#### Directories

Using a directory path with a space in it causes the install to fail (for example, using the default home directory of the Windows user, where you've possibly used your full name). This is [an open issue](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/1380).

Additionally, using a directory path in Windows file system mount points (such as `/mnt/c` or `/mnt/d`) [results in permissions issues](https://gitlab.com/gitlab-org/gitlab/-/issues/347422#note_757891300). Instead, you must use a path inside the WSL OS, such as inside `/home/<user>/`. If you must access the files from Windows, you can go to `\\wsl$` in Explorer to browse the file system. For example, `/home/sid/dev/kdk` would be visible at `\\wsl$\Ubuntu-20.04\home\sid\dev\kdk`.

#### Performance

WSL allocates up to 50% of your RAM by default for the Linux OS.

Increase the allocation to WSL to meet the minimum requirements. See [Supported methods](../README.md#supported-methods).

## Apply custom patches for Ruby

Some functions (and specs) require a special Ruby installed with additional [patches](https://gitlab.com/gitlab-org/gitlab-build-images/-/tree/master/patches/ruby).
These patches are already applied when running on KhulnaSoft CI/CD or when using KhulnaSoft Compose Kit,
but since KhulnaSoft Development Kit uses `mise` they must be manually enabled.

To recompile Ruby with adding additional patches do the following:

```shell
mise uninstall ruby

# Compile Ruby 3.3.7
export RUBY_APPLY_PATCHES="$(cat <<EOF
https://gitlab.com/gitlab-org/gitlab-build-images/-/raw/master/patches/ruby/3.3/thread-memory-allocations.patch
EOF
)"
mise install ruby 3.3.7
```

You can later verify that patches were properly applied:

```shell
$ ruby -e 'puts Thread.trace_memory_allocations'
false
```

## Network restricted environments

In a network restricted environment, you might not be able to freely access certain URLs. To validate the installation, KDK requires access to the following during bootstrap:

```plaintext
https://download.redis.io/
https://cache.ruby-lang.org/
https://classic.yarnpkg.com/
https://dl.google.com/
https://dl.min.io/
https://dl.yarnpkg.com/
https://ftp.postgresql.org/
https://github.com/
https://gitlab.com/
https://index.rubygems.org/
https://nodejs.org/
https://objects.githubusercontent.com/
https://rubygems.org/
https://sh.rustup.rs/
https://static.rust-lang.org/
```

## Next Steps

After you've completed the steps on this page, [use KDK to install KhulnaSoft](_index.md#use-kdk-to-install-gitlab).
