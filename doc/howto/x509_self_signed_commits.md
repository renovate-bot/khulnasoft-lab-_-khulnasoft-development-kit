---
title: Using self-signed X.509 certificates for signed commits
---

KhulnaSoft supports the use of [signed commits using X.509 certificates](https://docs.gitlab.com/ee/user/project/repository/signed_commits/x509.html).
This tutorial creates a commit with a self signed X.509 certificate which is verified by the KDK. When complete the commit is displayed as verified on the commits page:

![Verified Commit](img/verified_commit.jpg)

To set up self-signed X.509 certificates for signed commits in KDK follow the steps below.
The commands can be run from any empty directory in the MacOS home folder unless otherwise specified.

1. [Create a CA certificate](#create-a-ca-certificate)
1. [Create an end-entity certificate](#create-an-end-entity-certificate)
1. [Import keys into `gpgsm` and add to trustlist](#import-keys-into-gpgsm-and-add-to-trustlist)
1. [Set up KDK to use the CA certificate you generated](#set-up-kdk-to-use-the-ca-certificate-you-generated)
1. [Set up a project](#set-up-a-project)
1. [Cleaning up](#cleaning-up)

## Create a CA certificate

1. Generate a 4069 bit CA certificate key file:

   ```shell
   openssl genrsa -out ca.key 4096
   ```

1. Generate the CA certificate:

   ```shell
   openssl req \
     -new \
     -x509 \
     -subj "/C=US/ST=California/L=San Francisco/O=KhulnaSoft/OU=dev/CN=kdk.test/emailAddress=root@kdk.test" \
     -days 3650 \
     -key ca.key \
     -out ca.crt
   ```

## Create an end-entity certificate

1. Generate a 4096 bit Git key file:

   ```shell
   openssl genrsa -out git.key 4096
   ```

1. Generate the end-entity certificate:

   ```shell
   openssl req \
     -new \
     -subj "/C=US/ST=California/L=San Francisco/O=KhulnaSoft/OU=dev/CN=kdk.test/emailAddress=root@kdk.test" \
     -key git.key  \
     -out git.csr
   ```

1. Add more fields to the certificate:

   ```shell
   openssl x509 -req -days 3650 -in git.csr -CA ca.crt -CAkey ca.key -extfile <(
       echo "subjectAltName = DNS:gitlab.test,email:test@example.com,email:test2@example.com"; \
       echo "keyUsage = critical,digitalSignature"
       echo "subjectKeyIdentifier = hash"
       echo "authorityKeyIdentifier = keyid"
       echo "crlDistributionPoints=DNS:gitlab.test,URI:http://example.com/crl.pem"
   ) -set_serial 1 -out git.crt
   ```

## Import keys into `gpgsm` and add to trustlist

1. Export your Git key:

   ```shell
   openssl pkcs12 -export -inkey git.key -in git.crt -name test -out git.p12
   ```

1. Export your CA key:

   ```shell
   openssl pkcs12 -export -inkey ca.key -in ca.crt -name test2 -out ca.p12
   ```

1. Import your CA key into `gpgsm`:

   ```shell
   gpgsm --import ca.p12
   ```

1. Import your Git key into `gpgsm`:

   ```shell
   gpgsm --import git.p12
   ```

1. Add the SHA1 fingerprint for the last two keys in `gpgsm --list-keys` to `~/.gnupg/trustlist.txt`:

   ```shell
   gpgsm --list-keys | grep 'sha1 fpr' | awk -F 'sha1 fpr: ' '{ print $2 " S relax" }' >> ~/.gnupg/trustlist.txt
   ```

1. Suppress [`DirMngr` checking for revoked certificates](https://gnupg.org/documentation/manuals/gnupg-2.0/Certificate-Options.html):

   ```shell
   echo "disable-crl-checks" >>  ~/.gnupg/gpgsm.conf
   ```

## Set up KDK to use the CA certificate you generated

1. In the KDK root directory:

   ```shell
   echo "export SSL_CERT_FILE=<path-to-ca.crt>" >> env.runit
   ```

1. Restart the KDK:

   ```shell
   kdk restart
   ```

1. In a Rails console:

   ```shell
   Feature.enable(:x509_forced_cert_loading)
   ```

## Set up a project

1. Create a user with email `test2@example.com`.
1. Create a project.
1. Clone the project.
1. Configure the Git client to sign commits:

   ```shell
   git config user.email test2@example.com
   git config user.signingkey $(gpgsm --list-keys | grep 'ID: ' | tail -n1 | awk -F': ' '{ print $2 }')
   git config gpg.program gpgsm
   git config gpg.format x509
   ```

1. Restart `gpg-agent`:

   ```shell
   gpgconf --kill gpg-agent
   ```

1. Make some changes and commit with signature:

   ```shell
   echo test > test && git add test && git commit -m "test" -S
   ```

1. Push the changes.
1. Look at the commits you just pushed in the KhulnaSoft UI (for example, `http://kdk.test:3000/root/test-signatures/-/commits/<branch_name>`).
   There should be a **Verified** badge next to the signed commit.

## Cleaning up

Some of these configurations should be removed once testing is complete.

1. Remove added keys from `gpgsm`:
   1. Run `gpgsm --list-keys` and find the last two key IDs.
   1. Delete each of them by running `gpgsm --delete-keys <key ID>`.
1. Remove the two SHA1 fingerprint keys you added to `~/.gnupg/trustlist.txt`.
1. Remove ignoring the certificate revocation list (CRL) setting from `gpgsm.conf`:
   1. Delete `disable-crl-checks` from `~/.gnupg/gpgsm.conf`.
1. Remove SSL certificate file from KDK:
   1. Delete `export SSL_CERT_FILE=path to ca.crt` from `env.runit`.
   1. Restart the KDK: `kdk restart`.
