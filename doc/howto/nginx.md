---
title: NGINX
---

Installing and configuring NGINX allows you to enable HTTPS (with SSL/TLS), HTTP/2 as
well as greater flexibility around HTTP routing.

## Install dependencies

You need to install NGINX:

```shell
# on macOS
brew install nginx

# on Debian/Ubuntu
apt install nginx

# on Fedora
yum install nginx
```

Versions of NGINX packaged with some Linux distributions might not work.
You should install the [Homebrew version of NGINX](https://formulae.brew.sh/formula/nginx) using
the [official NGINX installation](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/).

## Add entry to /etc/hosts

To be able to use a hostname instead of IP address, add a line to
`/etc/hosts`.

```shell
echo '127.0.0.1 kdk.test' | sudo tee -a /etc/hosts
```

`kdk.test` (or anything ending in `.test`) is recommended as `.test` is a
[reserved TLD for testing software](https://en.wikipedia.org/wiki/.test).

### Configuring a loopback device (optional)

> [!note]
> You can skip this step unless you need a [runner under Docker](runner.md#executing-a-runner-from-within-docker).

If you want an isolated network space for all the services of your
KDK, you can [add a loopback network interface](local_network.md).

## Update `kdk.yml`

Place the following settings in your `kdk.yml`:

```yaml
---
hostname: kdk.test
nginx:
  enabled: true
  http:
    enabled: true
```

## Update `kdk.yml` for HTTPS (optional)

Place the following settings in your `kdk.yml`:

```yaml
---
hostname: kdk.test
port: 3443
https:
  enabled: true
nginx:
  enabled: true
  ssl:
    certificate: kdk.test.pem
    key: kdk.test-key.pem
```

### Generate certificate

[`mkcert`](https://github.com/FiloSottile/mkcert) is needed to generate certificates.
Check out their [installation instructions](https://github.com/FiloSottile/mkcert#installation)
for all the different platforms.

On macOS, install with `brew`:

```shell
brew install mkcert nss
mkcert -install
```

Using `mkcert` you can generate a self-signed certificate. It also
ensures your browser and OS trust the certificate.

```shell
mkcert kdk.test
```

On Linux (e.g. KDK-in-a-box), you'll need `sudo` to install mkcert's generated CA certificate
in the system's trust store (`/usr/local/share/ca-certificates`). Also, you need to preserve your
user's `HOME` environment variable so it will install the rootCA.pem from your `$HOME`, not `/root`.

```shell
sudo --preserve-env=HOME mkcert -install
```

## Update `kdk.yml` for HTTP/2 (optional)

Place the following settings in your `kdk.yml`:

```yaml
---
hostname: kdk.test
port: 3443
https:
  enabled: true
nginx:
  enabled: true
  http2:
    enabled: true
  ssl:
    certificate: <path/to/file/kdk.test.pem>
    key: <path/to/file/kdk.test-key.pem>
```

## Configure KDK

Run the following to apply these changes:

```shell
kdk reconfigure
kdk restart
```

## Run

KhulnaSoft should now be available for:

- HTTP: <http://kdk.test:8080>
- HTTPS: <https://kdk.test:3443> (if you set up HTTPS).

KhulnaSoft Docs should now be available for:

- HTTP: <http://kdk.test:1313>
- HTTPS: <https://kdk.test:1313> (if you set up HTTPS).

## Troubleshooting

### `nginx: invalid option: "e"`

NGINX v1.19 supports the `-e` flag, but v1.18 does not. If you encounter this
error, use [NGINX's repositories](https://nginx.org/en/linux_packages.html)
to install the latest package instead of the one shipped with your distribution.
