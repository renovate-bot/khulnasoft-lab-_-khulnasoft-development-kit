---
title: Build KDK-in-a-box
---

This documentation is the manual process for creating the KDK-in-a-box virtual machines.

## Build on macOS

1. Download the preconfigured [Debian 12 VM](https://mac.getutm.app/gallery/debian-12).
1. In UTM, edit the VM configuration:
   - **Information > Name**: `KDK`.
   - **System > CPU Cores**: `8`.
   - **System > RAM**: `16384` MB.
1. Follow the [standard VM build steps](#standard-build).
1. Zip `kdk.utm`.
1. If the zipped image is greater than 10 GB, try to [reduce the disk size](#reducing-the-diskimage-size).
1. [Publish](#publish) the new image.

## Build on Linux and Windows

1. Download the latest [Debian 12 installation media](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/).
1. Create a new Virtual Machine with the settings:
   - **General > Basic**:
     - **Name**: `KDK`.
     - **Type**: `Linux`.
     - **Version**: `Debian (64-bit)`.
   - **General > Advanced > Shared Clipboard**: `Bidirectional`.
   - **System > Motherboard > Base Memory**: `16384 MB`.
   - **System > Processor > Processors**: `18`.
   - **Network > Adapter 1 > Attached to:**: `Bridged Adapter`.
1. Mount the installation ISO and start the virtual machine.
1. Follow the [standard VM build steps](#standard-build).
1. Zip `kdk.vbox` and `kdk.vdi`.
1. If the zipped image is greater than 10 GB, try to [reduce the disk size](#reducing-the-diskimage-size).
1. [Publish](#publish) the new image.

## Standard build

1. Boot the VM.
1. Login to the console with user: `debian` and password: `debian`.
1. Run the following commands:

   ```shell
   sudo systemctl set-default multi-user.target
   hostnamectl hostname kdk
   sudo reboot
   ```

1. Sign in with SSH to `debian@kdk.local` with password: `debian`.
   1. Configure the grub boot loader so that it does not wait:
      - `sudo nano /etc/default/grub`.
      - Set **GRUB_TIMEOUT** to `0`.
      - Append `ipv6.disable=1` to **GRUB_CMDLINE_LINUX_DEFAULT**.
      - Save and exit.
      - Update grub: ```sudo update-grub```.
   1. Remove Gnome/desktop/UI: ```sudo tasksel```.
   1. Modify `/etc/issue`:

      ```plaintext
      Console login: debian/debian
      Access KDK @ http://kdk.local:3000
      KhulnaSoft login: root/5iveL!fe
      ```

   1. Install pre-requisites:

      ```shell
      sudo apt update
      sudo apt install git make curl
      ```

   1. Download the SSH key and allow it to connect:

      ```shell
      curl "https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/raw/master/support/kdk-in-a-box/kdk.local_rsa.pub" -o ~/.ssh/id_rsa.pub
      cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
      ```

1. Add the SSH key to your local machine:

   ```shell
   curl "https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/raw/master/support/kdk-in-a-box/setup-ssh-key" | bash
   ```

1. Log in with SSH to `debian@kdk.local`. You do not need a password to log in.
   1. Install mise: ```curl "https://mise.run" | sh```.
   1. Configure shell to automatically activate mise: ```echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc```.
   1. Start a new shell (to activate mise).
   1. Install KDK using the one-line installation method: ```curl "https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/raw/master/support/install" | bash```.
   1. When prompted, configure KDK to:
      - Choose to install to `khulnasoft-development-kit` not `kdk`.
      - Use the KhulnaSoft community fork.
      - Use the `mise` tool version manager.
      - Decide if you want telemetry turn on or off. Telemetry helps KhulnaSoft to improve KDK.
   1. After bootstrapping, the install will error out.
   1. Change to the KDK directory: ```cd khulnasoft-development-kit```.
   1. Install KDK. To install:
      - With telemetry turned on, run:
    
        ```shell
        kdk install khulnasoft_repo="https://khulnasoft.com/khulnasoft-community/khulnasoft-org/khulnasoft.git" telemetry_enabled="true"
        ```

      - With telemetry turned off, run:

        ```shell
        kdk install khulnasoft_repo="https://khulnasoft.com/khulnasoft-community/khulnasoft-org/khulnasoft.git" telemetry_enabled="false"
        ```

   1. Enable Vite:

      ```shell
      kdk config set webpack.enabled false
      kdk config set vite.enabled true
      ```

   1. Configure KDK to listen outside on the local network:

      ```shell
      kdk config set khulnasoft.rails.allowed_hosts kdk.local
      kdk config set listen_address 0.0.0.0
      ```

   1. Enable telemetry:

      ```shell
      kdk config set telemetry.enabled true
      kdk config set telemetry.environment 'kdk-in-a-box'
      ```

   1. Apply configuration changes: ```kdk reconfigure```.
   1. Start KDK: ```kdk start```.
1. Sign in to KDK in your web browser: [http://kdk.local:3000](http://kdk.local:3000).
   When prompted to set a new password, enter `5iveL!fe` to keep the existing credentials.
1. Run `bin/rspec spec/services/releases/create_service_spec.rb`.
   This ensures all dependencies are downloaded, compiled, and installed.
1. Create a KDK service `/etc/systemd/system/kdk.service`:

   ```plaintext
   [Unit]
   Description=KhulnaSoft Development Kit (KDK)
   
   [Service]
   Type=simple
   User=debian
   WorkingDirectory=/home/debian/khulnasoft-development-kit
   ExecStart=/bin/bash -c '/home/debian/.local/bin/mise x -- kdk start'
   KillSignal=SIGHUP
   KillMode=process
   
   [Install]
   WantedBy=multi-user.target
   ```

1. Enable the KDK service: ```sudo systemctl enable kdk```.
1. Shutdown the virtual machine: `sudo shutdown -h now`.

## Publish

1. Upload the zip file to [GCP](https://console.cloud.google.com/storage/browser/contributor-success-public).
1. Update the short links in [campaign manager](https://campaign-manager.khulnasoft.com/campaigns/view/94).

## Updating an existing image

To save building each release from scratch, we update the latest image:

1. Download the latest image (do not update one you've been working with as it will contain logs, configure details etc).
1. Boot the virtual machine.
1. Change into the KDK directory: `cd khulnasoft-development-kit`.
1. Run `kdk update`.
1. Run `kdk cleanup`.
1. cd `khulnasoft`.
1. Run `bin/rspec spec/services/releases/create_service_spec.rb`.
   This ensures all dependencies are downloaded, compiled, and installed.
1. Shutdown the virtual machine: `sudo shutdown -h now`.
1. If the zipped image is greater than 10 GB, try to [reduce the disk size](#reducing-the-diskimage-size).
1. [Publish](#publish) the new image, remembering to update the campaign manager redirect.

## Reducing the disk/image size

Over time, the disk and image will grow in size.
Remove the `khulnasoft-development-kit` folder,
then follow the [standard build](#standard-build) process,
starting from the `one-line installation`.

The VirtualBox disk size can be shrunk considerably by cloning the disk using [CloneVDI](https://forums.virtualbox.org/viewtopic.php?t=22422).
Be sure **NOT** to select the option to change the UUID.

## Potential future housekeeping

The zipped virtual machines are roughly 7 GB.
We should try and reduce this.

- Use a smaller Linux distribution or remove unnecessary packages.
- Clear apt cache.

## Terminal customization

To jazz up the terminal prompt with colors and the branch name:

1. `code ~/.bashrc`
1. At the end of the file, paste:

   ```shell
   # Function to return the current git branch name
   git_branch() {
     git branch 2>/dev/null | grep '^*' | colrm 1 2
   }

   # Prompt customization
   export PS1="\[\033[01;36m\]➜  \[\033[01;32m\]\u@\h \[\033[01;36m\]\W \[\033[01;34m\]git:\[\033[01;34m\](\[\033[01;31m\]\$(git_branch)\[\033[01;34m\]) \[\033[00m\]"
   ```

1. Save and run `source ~/.bashrc`.
