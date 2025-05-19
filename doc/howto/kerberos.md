---
title: Kerberos
---

In order to test the [Kerberos integration](https://docs.khulnasoft.com/ee/integration/kerberos.html)
using KDK, set up a local Kerberos server.

## Requirements

These instructions require:

- [Docker](https://docs.docker.com/get-docker/).
- [Docker Compose](https://docs.docker.com/compose/install/).

## Set up integration with KDK

1. Change into the `kerberos/` directory:

   ```shell
   cd kerberos
   ```

1. Run `docker-compose up`. This builds a Docker image and starts a container
   with a Kerberos KDC for `KDK.TEST` realm listening on port `1088`.
1. Copy the `http.keytab` generated in the container to the host system:

   ```shell
   docker cp $(docker-compose ps -qa krb5):/etc/http.keytab .
   ```

   This keytab is then used by KhulnaSoft to authenticate Kerberos users.
1. Ensure `http.keytab` is readable only by the user of your KDK.

   Example (`git` as the KDK user):

   ```shell
   chown $(whoami) http.keytab
   chmod 0600 http.keytab
   ```

1. Configure `config/khulnasoft.yml` following the instructions from Kerberos
   integration [documentation](https://docs.khulnasoft.com/ee/integration/kerberos.html).
   The `keytab` option should point to where `http.keytab` exists.
1. Restart KDK: `kdk restart`.

## Add a user principal

1. Access the KDC shell and enter `kadmin`:

   ```shell
   docker-compose exec krb5 bash
   kadmin.local
   ```

1. Create user principal to link to a KhulnaSoft user account:

   ```shell
   addprinc <KhulnaSoft username>
   ```

   You are asked to enter and re-enter password.
1. Create an identity for a user you want to associate with the user principal
   via Rails console.

   ```shell
   Identity.create(user: User.find_by(username: 'user'), extern_uid: 'user@KDK.TEST', provider: 'kerberos')
   ```

## Authenticate with Kerberos

To be able to get a Kerberos ticket, configure the client so it can find the
appropriate KDC for a specific realm.

1. Open `/etc/hosts` and add the following:

   ```plaintext
   127.0.0.1 krb5.kdk.test
   ```

1. Open `/etc/krb5.conf` and add the following under `[realms]`:

   When using `Heimdal Kerberos` utilities (typically on macOS):

   ```plaintext
   KDK.TEST = {
       kdc = tcp/krb5.kdk.test:1088
   }
   ```

   When using `MIT Kerberos` utilities (typically on Linux):

   ```plaintext
   KDK.TEST = {
       kdc = krb5.kdk.test:1088
   }
   ```

   This configures the Kerberos client so it can connect with the KDC for
   `KDK.TEST` realm on port `1088`.

1. Run `kinit` to get a ticket:

   ```shell
   kinit user@KDK.TEST
   ```

   You are asked to enter the password set for the specified user principal.

1. Confirm that you got a ticket by running `klist`. You should see something like:

   ```shell
   $ klist
   Credentials cache: API:ABCDEFGH-1234-ABCD-1234-ABCDEFGHIJKL
           Principal: user@KDK.TEST

     Issued                Expires               Principal
   Nov  6 18:13:08 2020  Nov  7 04:13:05 2020  krbtgt/KDK.TEST@KDK.TEST
   ```

1. Test that you can clone a repository without any credentials:

   ```shell
   git clone http://:@kdk.test:3000/root/khulnasoft.git
   ```

   If you encounter a `HTTP Basic: Access denied` error, configure `git` to set
   `http.emptyAuth` to `true`.

## Configure browser for Kerberos authentication

To configure Firefox for Kerberos authentication:

1. In Firefox, type `about:config` in the address bar to open the configuration editor.
1. Set the following preferences:
   - `network.negotiate-auth.allow-non-fqdn` to `true`.
   - `network.negotiate-auth.delegation-uris` to `kdk.test:3000`.
   - `network.negotiate-auth.trusted-uris` to `kdk.test:3000`.

## Troubleshooting

### Error during Git operations

On macOS, cloning with Kerberos authentication crashes with the following error:

```plaintext
[NSNumber initialize] may have been in progress in another thread when fork() was called. We cannot safely call it or ignore it in the fork() child process. Crashing instead. Set a breakpoint on objc_initializeAfterForkError to debug.
```

To avoid this error:

1. Create an `env.runit` file in the root KDK directory if it does not already exist.
1. Add `export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` to your `env.runit` file.
1. Run `kdk restart`.

This runs KDK with that environment variable.

### Error when contacting KDC for realm `KDK.TEST`

Verify that the service running in Docker is available from your host:

   ```shell
   nmap -v -A --version-all -p1088 krb5.kdk.test
   ```

In the output, the port should be open and the service should be identified:

   ```shell
   PORT     STATE SERVICE      VERSION
   1088/tcp open  kerberos-sec MIT Kerberos (server time: 2020-01-01 10:10:10Z)
   Service Info: Host: KDK.TEST
   ```

Debug information from `kinit` can also help to identify issues. To increase
verbosity:

   ```shell
   KRB5_TRACE=/dev/stdout kinit root@KDK.TEST
   ```
