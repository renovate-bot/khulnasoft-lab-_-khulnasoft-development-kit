---
title: Use VS Code Remote with a KDK workstation
---

This is an advanced KDK installation that uses a minimal remote image for
development.

This remote workstation is intended for fetching, developing, and pushing code
changes to KhulnaSoft. Having a YubiKey is required for this because of security
considerations.

To create the workstation:

1. [Set up SSH](#set-up-ssh)
1. [Create a VM](#create-a-vm)
1. [Set up SSH Agent Forwarding](#set-up-ssh-agent-forwarding)
1. [Use KDK to install KhulnaSoft](#use-kdk-to-install-gitlab)
1. [Set up VS Code Remote](#set-up-vs-code-remote)

## Set up SSH

1. Make sure you have at least OpenSSH 8.2 installed on your machine:
   - On macOS: `brew install openssh`
   - On Ubuntu/Debian: `sudo apt install openssh-client`
1. [Generate an SSH key pair for your FIDO/U2F hardware security key](https://docs.gitlab.com/ee/ssh/#generate-an-ssh-key-pair-for-a-fidou2f-hardware-security-key)
1. Add the newly generated public SSH key to your [KhulnaSoft](https://docs.gitlab.com/ee/ssh/#add-an-ssh-key-to-your-gitlab-account) and [GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) profiles:
   - If you generated a resident ED25519-SK key, the profile is in `~/.ssh/id_ed25519_sk.pub`.
   - If you generated a non-resident ECDSA-SK key, the profile is in `~/.ssh/id_ecdsa_sk.pub`.

## Create a VM

### Google Compute Engine

You can create a Google Cloud Compute VM here - <https://console.cloud.google.com/compute/instances?project=gitlab-internal-153318>

Here are the recommended settings for creating a GCE VM:

- Name: yourname-workstation
- Region: Cheapest low CO2 region physically closest to you available
- Instance type: `e2-standard-4` (`e2-standard-8` if you need more vCPUs)
- Boot Disk: 20GB Balanced PD /w Ubuntu 21.10 Minimal. 20GB is the minimum required size, because the approximate size
  of a minimal KDK install along with the system packages is around ~14GB.
- Security: Secure Boot, vTPM, Integrity Monitoring
- SSH: Add your newly created FIDO2 public SSH key and enable "Block project-wide SSH keys"

This gets you an instance with 4vCPUs, 16GB of memory and a 20GB balanced PD
with Ubuntu 21.10 minimal.

You can do this via the Google Cloud web UI, the `gcloud` console command, or the
Google Cloud REST API.

Here's the `gcloud` equivalent terminal command:

```shell
gcloud compute instances create [YOUR_INSTANCE_NAME] --project=gitlab-internal-153318 --zone=[YOUR_INSTANCE_ZONE] --machine-type=e2-standard-4 --network-interface=network-tier=PREMIUM,subnet=default --metadata=block-project-ssh-keys=true,ssh-keys=[YOUR_SSH_KEY] --maintenance-policy=MIGRATE --service-account=696404988091-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2110-impish-v20211014,mode=rw,size=20,type=projects/gitlab-internal-153318/zones/[YOUR_INSTANCE_ZONE]/diskTypes/pd-balanced --shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
```

Here's the Google Cloud REST API equivalent:

`POST https://www.googleapis.com/compute/v1/projects/gitlab-internal-153318/zones/[YOUR_INSTANCE_ZONE]/instances`

```json
{
  "canIpForward": false,
  "confidentialInstanceConfig": {
    "enableConfidentialCompute": false
  },
  "deletionProtection": false,
  "description": "",
  "disks": [
    {
      "autoDelete": true,
      "boot": true,
      "deviceName": "instance-1",
      "diskEncryptionKey": {},
      "initializeParams": {
        "diskSizeGb": "20",
        "diskType": "projects/gitlab-internal-153318/zones/[YOUR_INSTANCE_ZONE]/diskTypes/pd-balanced",
        "labels": {},
        "sourceImage": "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2110-impish-v20211014"
      },
      "mode": "READ_WRITE",
      "type": "PERSISTENT"
    }
  ],
  "displayDevice": {
    "enableDisplay": false
  },
  "guestAccelerators": [],
  "labels": {},
  "machineType": "projects/gitlab-internal-153318/zones/[YOUR_INSTANCE_ZONE]/machineTypes/e2-standard-4",
  "metadata": {
    "items": [
      {
        "key": "block-project-ssh-keys",
        "value": "true"
      },
      {
        "key": "ssh-keys",
        "value": "[YOUR_SSH_PUBLIC_KEY]"
      }
    ]
  },
  "name": "[YOUR_INSTANCE_NAME]",
  "networkInterfaces": [
    {
      "accessConfigs": [
        {
          "name": "External NAT",
          "networkTier": "PREMIUM"
        }
      ],
      "subnetwork": "projects/gitlab-internal-153318/regions/[YOUR_INSTANCE_REGION]/subnetworks/default"
    }
  ],
  "reservationAffinity": {
    "consumeReservationType": "ANY_RESERVATION"
  },
  "scheduling": {
    "automaticRestart": true,
    "onHostMaintenance": "MIGRATE",
    "preemptible": false
  },
  "serviceAccounts": [
    {
      "email": "696404988091-compute@developer.gserviceaccount.com",
      "scopes": [
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring.write",
        "https://www.googleapis.com/auth/servicecontrol",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/trace.append"
      ]
    }
  ],
  "shieldedInstanceConfig": {
    "enableIntegrityMonitoring": true,
    "enableSecureBoot": true,
    "enableVtpm": true
  },
  "tags": {
    "items": []
  },
  "zone": "projects/gitlab-internal-153318/zones/[YOUR_INSTANCE_ZONE]"
}
```

## Set up SSH agent forwarding

1. Set up SSH agent forwarding on your local machine (in `~/.ssh/config`)

   ```plain
   Host remote-workstation
     HostName [REMOTE_WORKSTATION_EXTERNAL_IP]
     User [YOUR_USERNAME]
     ForwardAgent yes
   ```

1. SSH into your remote machine:

   ```shell
   ssh remote-workstation
   ```

1. Make sure the VM is up to date:

   ```shell
   sudo apt update && sudo apt upgrade && sudo apt autoremove
   ```

1. Verify SSH authentication to KhulnaSoft.com and GitHub.com works as expected:

   ```shell
   ssh git@gitlab.com
   # Welcome to KhulnaSoft, @[YOUR_KHULNASOFT_HANDLE]!

   ssh git@github.com
   # Hi [YOUR_GITHUB_HANDLE]! You've successfully authenticated, but GitHub does not provide shell access.
   ```

## Use KDK to install KhulnaSoft

### One-line installation (Recommended)

These steps are based on the instructions in <https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/master/doc/index.md#one-line-installation>.

1. Install `git` and `make`:

   ```shell
   sudo apt install git make
   ```

1. Use KDK to install KhulnaSoft:

   ```shell
   curl "https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/raw/main/support/install" | bash
   ```

### Manual installation

These steps are based on the instructions in <https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/master/doc/advanced.md#ubuntu-and-debian>.

1. Install `git`, `make`, `yarn`, PostgreSQL, and Go:
   1. `sudo apt install git`
   1. `sudo apt install make`
   1. `sudo apt install yarnpkg`
   1. `sudo ln -s /usr/bin/yarnpkg /usr/bin/yarn`
   1. `sudo apt install postgresql postgresql-contrib`
   1. `sudo apt install golang`
1. Clone the KDK repository from the home directory on your remote machine:
   1. `git clone git@gitlab.com:gitlab-org/khulnasoft-development-kit.git kdk`
   1. `cd kdk`
1. Install the pre-requisite packages:
   1. `make bootstrap-packages`
1. Install `minio`:
   1. `sudo curl "https://dl.min.io/server/minio/release/linux-amd64/minio" --output /usr/local/bin/minio`
   1. `sudo chmod +x /usr/local/bin/minio`
1. Install `ruby`:
   1. `sudo apt install rbenv`
   1. `mkdir -p "$(rbenv root)"/plugins`
   1. `git clone git@github.com:rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build`
   1. Install the Ruby versions listed in `.tool-versions`:
      1. For example: `rbenv install 2.7.4`
      1. For example: `rbenv install 3.0.2`
   1. Set the global Ruby version to the first Ruby version listed in `.tool-versions`, for example, `rbenv global 2.7.4`.
   1. `echo $'\n### rbenv ###\n\neval "$(rbenv init -)"' >> ~/.bashrc`
   1. `source ~/.bashrc`
1. Use KDK to install KhulnaSoft:
   1. `gem install khulnasoft-development-kit`
   1. `kdk install khulnasoft_repo=git@gitlab.com:gitlab-org/gitlab.git`

## Set up VS Code Remote

These steps are based on the instructions in <https://code.visualstudio.com/docs/remote/ssh>.

1. Install VS Code on your local machine.
1. Install the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension.
1. Run `Remote-SSH: Connect to Host...` from the command palette.
1. Connect to `username@remote-ip`.
1. Open the `kdk/gitlab` directory.
1. Trust the directory.
1. Run `Forward a Port` from the command palette.
1. Enter `3000` in the port number prompt.
1. Open `http://localhost:3000` in your local machine browser.
