---
title: Install and configure KDK
---

[[_TOC_]]

KhulnaSoft Development Kit (KDK) provides a local environment for developing KhulnaSoft and related projects. For example:

- [Gitaly](https://khulnasoft.com/khulnasoft-org/gitaly).
- [KhulnaSoft Docs](https://khulnasoft.com/khulnasoft-org/technical-writing/docs-khulnasoft-com).

To ensure a smooth installation of KDK, you should delete any previously cloned repositories. This prevents conflicts or errors that may arise during the installation process.

To install KDK, you must:

1. Install prerequisites.
1. Install dependencies and the KDK:
   - In a single step with the [one-line installation](#one-line-installation). This method installs dependencies
     and the KDK with one command.
   - In two steps with the [simple installation](#simple-installation). This method separates dependency installation
     and KDK installation, for more control and customization. When using the simple installation method, you:

     1. Install dependencies [using `mise`](#install-dependencies-using-mise) or [manually](#install-dependencies-manually).
     1. [Use KDK to install KhulnaSoft](#use-kdk-to-install-khulnasoft).

Use a [supported operating system](../README.md#supported-platforms).

## Install prerequisites

You must have [Git](https://git-scm.com/downloads) and `make` installed to install KDK.

### macOS

The macOS installation requires Homebrew, Git, and `make`. Git and `make` are installed by default, but
Homebrew must be installed manually. Follow the guide at [brew.sh](https://brew.sh/).

If you have upgraded macOS, install the Command Line Tools package for Git to work:

```shell
xcode-select --install
```

### Ubuntu or Debian

  1. Update the list of available packages:

     ```shell
     sudo apt update
     ```

  1. Add an `apt` repository for the latest version of Git.

     - For Ubuntu, install `add-apt-repository` and add a PPA repository:

       ```shell
       sudo apt install software-properties-common
       sudo add-apt-repository ppa:git-core/ppa
       ```

     - For Debian, add a [backport repository](https://backports.debian.org/Instructions/) for your
       Debian version.

  1. Install `git` and `make`:

     ```shell
     sudo apt install git make
     ```

### Arch and Manjaro Linux

Update the list of available packages and install `git` and `make`:

```shell
sudo pacman -Syu git make
```

### Other platforms

Install using your system's package manager.

## One-line installation

The one-line installation:

1. Prompts the user for a KDK directory name. The default is `kdk`.
1. From the current working directory, clones the KDK project into the specified directory.
1. Runs `kdk install`.
1. Runs `kdk start`.

Before running the one-line installation, ensure [the prerequisites are installed](#install-prerequisites).
Then install KDK with:

```shell
curl "https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/raw/master/support/install" | bash
```

If you have any post-installation problems, see [Resolve installation errors](#resolve-installation-errors).

## Simple installation

After prerequisites are installed, you can install KDK dependencies and KDK itself.

### Install dependencies

Before [using KDK to install KhulnaSoft](#use-kdk-to-install-khulnasoft), you must install and configure some third-party
software, either:

- [Using `mise`](#install-dependencies-using-mise)
- [Manually](#install-dependencies-manually).

#### Install dependencies using `mise`

Installing and managing dependencies automatically lets KDK manage dependencies for you using
[`mise`](https://mise.jdx.dev/).

1. Clone the `khulnasoft-development-kit` repository into your preferred location, if you haven't previously:

   ```shell
   git clone https://github.com/khulnasoft-lab/khulnasoft-development-kit.git kdk
   ```

1. Change into the KDK project directory:

   ```shell
   cd kdk
   ```

1. Configure KDK to use `mise` instead of `asdf`:

   ```shell
   cat << EOF > kdk.yml
   ---
   asdf:
      opt_out: true
   mise:
      enabled: true
   EOF
   ```

1. Install all dependencies using `mise`:

   ```shell
   make bootstrap
   ```

#### Install dependencies manually

Use your operating system's package manager to install and managed dependencies.
[Advanced instructions](advanced.md) are available to help. These include instructions for macOS,
Ubuntu, and Debian (and other Linux distributions), FreeBSD, and Windows 10. You should
regularly update these. Generally, the latest versions of these dependencies work fine. Install,
configure, and update all of these dependencies as a non-root user. If you don't know what a root
user is, you very likely run everything as a non-root user already.

After installing KDK dependencies:

1. Clone the `khulnasoft-development-kit` repository into your preferred location:

   ```shell
   git clone https://github.com/khulnasoft-lab/khulnasoft-development-kit.git kdk
   ```

   The default directory created is `kdk`. This can be customized by appending a different directory name to the `git clone` command.

1. Change into the KDK project directory:

   ```shell
   cd kdk
   ```

1. Install the `khulnasoft-development-kit` gem:

   ```shell
   gem install khulnasoft-development-kit
   ```

1. Install all the Ruby dependencies:

   ```shell
   bundle install
   ```

### Use KDK to install KhulnaSoft

To install KhulnaSoft by using KDK, use one of these methods:

- For those who have write access to the [KhulnaSoft.org group](https://khulnasoft.com/khulnasoft-org), you should install
  using SSH:

  ```shell
  kdk install khulnasoft_repo=git@khulnasoft.com:khulnasoft-org/khulnasoft.git
  ```

- Otherwise, install using HTTPS:

  ```shell
  kdk install
  ```

If `kdk install` doesn't work, see [Resolve installation errors](#resolve-installation-errors).

Use `kdk install shallow_clone=true` for faster clones that consumes less disk-space. The clone
process uses [`git clone --depth=1`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt).

Use `kdk install blobless_clone=false` for clones without any `git clone`
arguments. `git clone` commands will consume more disk-space and be slower
however.

### Use KDK to install KhulnaSoft FOSS

If you want to run KhulnaSoft FOSS, install KDK using
[the KhulnaSoft FOSS project](install_alternatives.md#install-using-khulnasoft-foss-project).

### Use KDK to install your own KhulnaSoft fork

If you want to run KhulnaSoft from your own fork, install KDK using
[your own KhulnaSoft fork](install_alternatives.md#install-using-your-own-khulnasoft-fork).

## Set up `kdk.test` hostname

You should set up `kdk.test` as a local hostname. For more information, see
[Local network binding](howto/local_network.md).

## Resolve installation errors

During the `kdk install` process, you may encounter some dependency-related
errors. If these errors occur:

- Run `kdk doctor`, which can detect problems and offer possible solutions.
- Refer to the [troubleshooting page](troubleshooting/_index.md).
- [Open an issue in the KDK tracker](https://github.com/khulnasoft-lab/khulnasoft-development-kit/issues).
- Run [`kdk pristine`](kdk_commands.md#kdk-pristine) to reinstall dependencies, remove temporary files, and clear caches.

## Use KhulnaSoft Enterprise features

For instructions on how to generate a developer license, see [Developer onboarding](https://handbook.khulnasoft.com/handbook/engineering/developer-onboarding/#working-on-khulnasoft-ee-developer-licenses).

The developer license is generated for you to get access to [Premium or Ultimate](https://about.khulnasoft.com/handbook/marketing/brand-and-product-marketing/product-and-solution-marketing/tiers/) features in your KDK. You must add this license to your KDK instance, not your KhulnaSoft.com account.

### Configure developer license in KDK

To configure your developer license in KDK:

1. [Add your developer license](https://docs.khulnasoft.com/ee/administration/license_file.html) to KhulnaSoft running in KDK.
1. Add the following configuration to your `kdk.yml` depending on your license type:

   - If you're using a license generated from the production Customers Portal, run:

     ```shell
     kdk config set license.customer_portal_url https://customers.khulnasoft.com
     kdk config set license.license_mode prod
     ```

   - To use custom settings, add:

     ```shell
     kdk config set license.customer_portal_url <customer portal url>
     kdk config set license.license_mode <license mode>
     ```

1. Run `kdk reconfigure` to reconfigure KDK.
1. Run `kdk restart` to restart KDK.

If you're using a license generated from the staging Customers Portal, you don't need to add anything to `kdk.yml`. The following environment variables are
already set by default:

```shell
export KHULNASOFT_LICENSE_MODE=test
export CUSTOMER_PORTAL_URL=https://customers.staging.khulnasoft.com
```

## Post-installation

After successful installation, see:

- [KDK commands](kdk_commands.md).
- [KDK configuration](configuration.md).

After installation, [learn how to use KDK](howto/_index.md) to enable other features.

## Update KDK

For information about updating KDK, see [Update KDK](kdk_commands.md#update-kdk).

## Create new KDK

If you have problems with your current KDK installation,
first try the following troubleshooting options:

- To identify and resolve common issues, run [`kdk doctor`](kdk_commands.md#check-kdk-health).
- For data-related issues, run [`kdk reset-data`](kdk_commands.md#reset-data)
  to purge and reseed your database.
- For dependency issues like Ruby gems or Yarn modules,
  run [`kdk pristine`](kdk_commands.md#kdk-pristine).

For other issues, refer to the [KDK troubleshooting](troubleshooting/_index.md) page.

If your problem is not resolved, create a new KDK installation:

1. Open a terminal and go to the parent folder that
   contains your `khulnasoft-development-kit` installation.
1. Clone the KDK repository into a new directory:
   `git clone https://github.com/khulnasoft-lab/khulnasoft-development-kit.git kdk-2`.
1. Change to the new directory: `cd kdk-2`.
1. Use KDK to install KhulnaSoft: `kdk install`
1. Follow the [Removing KDK](#removing-kdk) steps to remove your old installation.

## Removing KDK

You can completely remove the KDK by shutting it down and deleting the parent directory.

From the root of your KDK install:

```shell
kdk stop
cd ..
rm -rf kdk
```

You might want to use a tool like [`git-recon`](https://khulnasoft.com/leipert-projects/git-recon)
to make sure you don't have uncommitted or unpushed work in any project inside the KDK folder.
