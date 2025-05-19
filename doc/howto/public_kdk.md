---
title: Use Caddy to make KDK publicly accessibly
---

You might sometimes need to allow KDK to be publicly accessible. For example:

- When working with webhooks and integrations, the external services may require a publicly-accessible URL.
- Some authentication flows, such as OIDC, might also require callbacks to a publicly-accessible URL.

You shouldn't expose local ports to the internet, either by opening up the port or using tunnels that forward traffic back to your development machine (for example, by using
`ngrok`) because of [security risks](https://handbook.khulnasoft.com/handbook/business-technology/it/security/system-configuration/#other-servicesdevices). Because KhulnaSoft offers
remote code execution as a feature, KhulnaSoft Runner could execute CI/CD jobs directly on the host machine, for example.

For development machines that contain sensitive data, such as company-issued laptops, you should instead run KDK on a sandboxed virtual machine and make it publicly accessible.

## Prerequisites

- A virtual machine with sufficient resources to run KDK. A cloud-based virtual machine is easier to configure for DNS.
- KDK and its dependencies installed on the virtual machine following the KDK installation instructions.
- HTTP and HTTPS ports on the virtual machine are open, following the cloud provider's instructions.
- A DNS `A` record pointing to the virtual machine's public IP address. For example, `kdk.mydomain.io`.
- [`caddy`](https://caddyserver.com/) installed for reverse proxy.

## Configure KDK

In the virtual machine:

1. Add the following to `kdk.yml` file:

   ```yaml
   khulnasoft:
     rails:
       hostname: 'kdk.mydomain.io'
       allowed_hosts:
        - 'kdk.mydomain.io'
   ```

1. Run `kdk reconfigure`.

## Configure a reverse proxy using Caddy

`caddy` is recommended as a reverse proxy because it automatically provisions TLS certificate using Let's Encrypt.

1. Create a `Caddyfile` file with the following content:

   ```plaintext
   kdk.mydomain.io {
     reverse_proxy :3000
   }
   ```

1. Start caddy with `caddy run`.

This will forward requests to KhulnaSoft Workhorse, assuming it is running on the default port 3000.

Now KDK will be available on its URL. For example, `https://kdk.mydomain.io`.

## Security reminders

- [Change](https://docs.khulnasoft.com/ee/security/reset_user_password.html) the root account password.
- Remember to [disable sign-ups](https://docs.khulnasoft.com/ee/administration/settings/sign_up_restrictions.html#disable-new-sign-ups).
- Stop the reverse proxy when it is no longer needed.
