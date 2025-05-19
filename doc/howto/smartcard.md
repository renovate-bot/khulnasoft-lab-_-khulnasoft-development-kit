---
title: Smart Cards
---

Configuring smart cards allows logging into your local KhulnaSoft tenant using [an X.509 certificate](https://learn.microsoft.com/en-us/azure/iot-hub/reference-x509-certificates) stored on [a smart card device such as a YubiKey](https://www.yubico.com/resources/glossary/smart-card/), or using a certificate from your operating system or browser certificate store.

## Installation

### Enable smart cards in the KDK

1. Ensure NGINX is enabled and configured with `https` in your local KDK. See [the NGINX documentation for a guide](nginx.md) on how to set this up.

1. Generate a new self-signed certificate for the subdomain which will be used to gather and accept the certificate. For this guide, we will be using the domain `smartcard.kdk.test`. Place the certificate and key in your KDK root directory. The easiest way to do this is using [mkcert](https://github.com/FiloSottile/mkcert).

   ```shell
   mkcert smartcard.kdk.test
   ```

1. Add the new hostname to `/etc/hosts`. This points to the same endpoint as the `hostfile` entry created for the [NGINX configuration](nginx.md#add-entry-to-etchosts). If you are using [a local loopback device](local_network.md), point the new `hostfile` entry to the same endpoint.

1. Ensure you know the location of the root certificate authority (CA) used to generate the subdomain certificate. If you are using `mkcert` , it can tell you where the root CA key is located. On macOS, this is usually at `/Users/$USER/Library/Application Support/mkcert/rootCA.pem`

   ```shell
   # shows the directory where the root certificate authority keys are located
   mkcert -CAROOT

   # view the file names of the mkcert root keys
   caroot="$(mkcert -CAROOT)" ; find $caroot/*

   # copy the name of the root certificate to the clipboard
   # this should be in the format /Users/some/directory/.../rootCA.pem if you are using mkcert
   caroot="$(mkcert -CAROOT)" ; find $caroot/* | tail -n 1 | pbcopy
   ```

1. Add the following to your `<kdk-root>/kdk.yml` file:

   ```yaml
   smartcard:
     enabled: true
     hostname: smartcard.kdk.test
     port: 3444 # this must be different than the port khulnasoft-rails is running on
     ssl:
       certificate: smartcard.kdk.test.pem
       key: smartcard.kdk.test-key.pem
       client_cert_ca: '<location of root certificate.pem>'
   ```

1. Ensure the `khulnasoft.rails.allowed_hosts` setting in `kdk.yml` includes the new smart card subdomain:

   ```yaml
   khulnasoft:
     rails:
       allowed_hosts:
         - 'kdk.test' # hostname specified in the top-level "hostname" setting
         - 'smartcard.kdk.test'
   ```

### Configure KDK

Run the following to apply these changes:

```shell
kdk reconfigure
kdk restart
```

## Testing certificate-based login

To generate a certificate and use it to log in to your local KDK tenant, follow these steps:

1. Generate a certificate using the `client_cert_ca` specified in `kdk.yml` . The certificate subject can be the username of the user you want to sign in as, or the email of the user. To generate with `mkcert` , use the following command:

   ```shell
   mkcert -client -pkcs12 'john.doe@example.com'
   ```

1. Add this certificate to your system or browser certificate store (the following is for macOS):
   1. Open the Keychain Access app.
   1. Select the **login** keychain on the left navigation.
   1. Select the **My Certificates** tab.
   1. Drag the generated `.p12` certificate file into the app to add it to the keychain.
   1. A prompt will appear asking for the certificate password. The default used by `mkcert` is "changeit".

1. If you are using Google Chrome as a browser, quit and re-open it to refresh the local certificate cache.

1. Navigate to your local KDK sign-in screen.

1. Select the "Smartcard" tab on the sign-in screen.

1. Select **Login with smartcard**.

1. You should now be logged in as a user with the username or email specified by the certificate.

## Configure smart card authentication with LDAP

If you have [set up KDK to manage an LDAP server](ldap.md) locally, you can test authenticating certificates against the LDAP server. For more information, see [allow LDAP authentication with smart cards](ldap.md#optional-allow-authentication-with-smart-cards).
