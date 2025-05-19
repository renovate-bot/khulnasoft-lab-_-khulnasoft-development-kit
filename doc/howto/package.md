---
title: Package managers
---

Set up KDK for specific package managers and package manager configurations.

## GoProxy

The GoProxy client enforces some specific constraints that make it unable to
work with a standard KDK install. It requires an https connection, and also
makes additional requests to port 443 regardless of the port used in the
GOPROXY environment variable.

These steps allow you to enable your KDK install with HTTPS and also
allow it to respond to requests on port 443.

1. Follow the [NGINX guide](nginx.md) to enable HTTPS. You must include the steps:
   - [Configuring a loopback device](nginx.md#configuring-a-loopback-device-optional).
   - [Update `kdk.yml` for HTTPS](nginx.md#update-kdkyml-for-https-optional).

  Your local KhulnaSoft should now be available at <https://kdk.test:3443> and <https://172.16.123.1:3443>

1. Clone the [Super Simple Proxy](https://khulnasoft.com/firelizzard/super-simple-proxy)
   project (authored by the same community contributor that contributed the GoProxy MVC!)

1. Run the proxy with the following command. The `pem` files are wherever you created
   them in the previous step.

  ```shell
  go run . -netrc -secure kdk.test:443 -key /path/to/kdk.test-key.pem -cert /path/to/kdk.test.pem -insecure kdk.test:80 -forward kdk.test,kdk.test:3443
  ```

You should now be able to access KhulnaSoft at <https://kdk.test> (port 443 is default for HTTPS).

You also need to prevent Go from making calls to <https://sum.golang.org>
to check the validity of your package (it is not aware of localhost or your
private packages). Run one of the following commands before you begin using the
Go client to install and work with Go packages. Otherwise, the Go client fails to fetch your private
packages.

```shell
# entirely disable downloading checksums for all Go modules
export GOSUMDB=off

# disable checksum downloads for all projects
export GONOSUMDB=kdk.test

# disable checksum downloads for projects within a namespace
export GONOSUMDB=kdk.test/namespace

# disable checksum downloads for a specific project
export GONOSUMDB=kdk.test/namepsace/project
```

You now should be able to fully test and work with the GoProxy in your local
KDK instance.
