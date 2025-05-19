---
title: Container Registry
---

Depending on your needs, you can set up Container Registry locally in the following ways:

- Display the Container Registry in the UI only (not push or pull images).
- Use the Container Registry as an insecure registry (can push and pull images).
- Use the Container Registry with a self-signed certificate (can push and pull images).

## Set up Container Registry to display in UI only

To set up Container Registry to display in the UI only (but not be able to push or pull images) add the following to your `kdk.yml`:

```yaml
registry:
  enabled: true
```

Then run the following commands:

1. `kdk reconfigure`.
1. `kdk restart`.

## Set up pushing and pulling of images over HTTP

To set up Container Registry to allow pushing and pulling of images over HTTP, you must have a Docker-compatible client
installed. For example:

- [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/).
- [Colima](https://github.com/abiosoft/colima).
- [`lima nerdctl`](https://github.com/containerd/nerdctl).
- [Rancher Desktop](https://rancherdesktop.io).
- [Podman](https://podman.io/)

In these instructions, we assume you [set up `registry.test`](local_network.md).

1. Update `kdk.yml` as follows:

   ```yaml
   hostname: kdk.test
   registry:
     enabled: true
     host: registry.test
     self_signed: false
     auth_enabled: true
     listen_address: 0.0.0.0
   ```

1. Locate the Docker daemon configuration file and set the `insecure-registries` directive to point to the local registry `registry.test:5100`:
   - For Rancher Desktop, see [modify Docker daemon configuration in Rancher Desktop VM](https://github.com/rancher-sandbox/rancher-desktop/discussions/1477).
   - For Colima, see [How to customize Docker config e.g. add insecure registries?](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md#how-to-customize-docker-config-eg-add-insecure-registries).
   - For general information, see the [CNCF documentation](https://distribution.github.io/distribution/about/insecure/#deploy-a-plain-http-registry).
1. Restart the Docker engine.
1. Run `kdk reconfigure`.
1. Run `kdk restart`.

After completing these instructions, you should be ready to work with the registry locally. See the
[Interacting with the local container registry](#interacting-with-the-local-container-registry)
section for examples of how to query the registry manually using `curl`.

### Set up pushing and pulling of images over HTTPS

This section is relevant if you set `self_signed: true` in your `kdk.yml`.

Since the registry is self-signed, Docker treats it as *insecure*. The certificate must be in your
KDK root, called `registry_host.crt`, and must be copied as `ca.crt` to the
[appropriate configuration location](https://distribution.github.io/distribution/about/insecure/#use-self-signed-certificates).

If you are using Docker Desktop for Mac, KDK includes the shorthand:

```shell
rm -f registry_host.{key,crt} && make trust-docker-registry
```

This places the certificate under `~/.docker/certs.d/$REGISTRY_HOST:$REGISRY_PORT/ca.crt`, *overwriting any existing certificate* at that path.

Afterwards, you **must restart Docker** to apply the changes.

### Observe the registry

Run `kdk tail registry`.

Example:

```plaintext
registry   : level=warning msg="No HTTP secret provided - generated random secret ...
registry   : level=info msg="redis not configured" go.version=go1.11.2 ...
registry   : level=info msg="Starting upload purge in 13m0s" go.version=go1.11.2 ...
registry   : level=info msg="using inmemory blob descriptor cache" go.version=go1.11.2 ...
registry   : level=info msg="listening on [::]:5100" go.version=go1.11.2 ...
```

Visit `$REGISTRY_HOST:$REGISTRY_PORT` (such as `registry.test:5100`) in your browser.
Any response, even a blank page, means that the registry is probably running. If the
registry is running, the output of `kdk tail` changes.

### Configure an insecure registry for KhulnaSoft CI/CD

If you're not using a self-signed certificate, you can instruct Docker to consider the registry as insecure. For example, Docker-in-Docker builds require an additional flag, `--insecure-registry`:

```yaml
# .gitlab-ci.yml

services:
  - name: docker:stable-dind
    command: ["--insecure-registry=registry.test:5100"]
```

### Configure a local Docker-based runner

For Docker-in-Docker builds to work in a local runner, you must also make the nested Docker
service trust the certificates by editing `volumes` under `[[runners.docker]]` in your
runner's `.toml` configuration to include:

```shell
$HOME/.docker/certs.d:/etc/docker/certs.d
```

replacing `$HOME` with the expanded path. For example

```toml
volumes = ["/Users/hfyngvason/.docker/certs.d:/etc/docker/certs.d", "/certs/client", "/cache"]
```

### Interacting with the local container registry

In this section, we assume you have obtained a [Personal Access Token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) with all permissions, and exported it as `KHULNASOFT_TOKEN` in your environment:

```shell
export KHULNASOFT_TOKEN=...
```

#### Using the Docker Client

- If you have authentication enabled, logging in is required.
- If you have a self-signed local registry, trusting the registry's certificates is required.

##### Log in to the registry

```shell
docker login kdk.test:5100 -u gitlab-token -p "$KHULNASOFT_TOKEN"
```

##### Build and tag an image

```shell
docker build -t kdk.test:5100/custom-docker-image .
```

##### Push the image to the local registry

```shell
docker push kdk.test:5100/custom-docker-image
```

#### Using HTTP

- If you have a self-signed certificate, you can add `--cacert registry_host.crt` or `-k` to the `curl` commands.
- If you have authentication enabled, you must obtain a bearer token for your requests:

  ```shell
  export KHULNASOFT_REGISTRY_JWT=`curl "http://gitlab-token:$KHULNASOFT_TOKEN@kdk.test:3000/jwt/auth?service=container_registry&scope=$SCOPE" | jq -r .token`
  ```

  where `$SCOPE` should be
  - `registry:catalog:*` to interact with the catalog
  - `repository:your/project/path:*` to interact with the images associated with a particular project

  Alternatively, you can obtain the token via the Rails console:

  ```ruby
  ::Auth::ContainerRegistryAuthenticationService.pull_access_token('your/project/path')
  ```

  To use the token, append it as a header flag to the `curl` command:

  ```shell
  -H "Authorization: Bearer $KHULNASOFT_REGISTRY_JWT"
  ```

The commands below assume a self-signed registry with authentication enabled, as this is the most complicated use case.

##### Retrieve a list of images available in the repository

```shell
curl --cacert registry_host.crt -H "Authorization: Bearer $KHULNASOFT_REGISTRY_JWT" \
  kdk.test:5100/v2/_catalog
```

```json
{
  "repositories": [
    "secure-group/docker-image-test",
    "secure-group/klar",
    "secure-group/tests/ruby-bundler/master",
    "testing",
    "ubuntu"
  ]
}
```

##### List tags for a specific image

```shell
curl --cacert registry_host.crt -H "Authorization: Bearer $KHULNASOFT_REGISTRY_JWT" \
  kdk.test:5100/v2/secure-group/tests/ruby-bundler/master/tags/list
```

```json
{
  "tags": [
    "3bf5c8efcd276bf6133ccb787e54b7020a00b99c",
    "ca928571c661c42dbdadc090f4ef78c8f2854dd9",
    "f7182b792a58d282ef3c69c2c6b7a22f78b2e950"
  ], "name": "secure-group/tests/ruby-bundler/master"
}
```

##### Get image manifest

```shell
curl --cacert registry_host.crt -H "Authorization: Bearer $KHULNASOFT_REGISTRY_JWT" \
  kdk.test:5100/v2/secure-group/tests/ruby-bundler/master/manifests/3bf5c8efcd276bf6133ccb787e54b7020a00b99c
```

```json
{
  "schemaVersion": 1,
  "name": "secure-group/tests/ruby-bundler/master",
  "tag": "3bf5c8efcd276bf6133ccb787e54b7020a00b99c",
  "architecture": "amd64",
  "fsLayers": [
      {
        "blobSum": "sha256:f9b473be28291374820c40f9359f7f1aa014babf44aadb6b3565c84ef70c6bca"
      },
  "..."
```

##### Get image layers

```shell
curl --cacert registry_host.crt \
  -H "Authorization: Bearer $KHULNASOFT_REGISTRY_JWT" \
  -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
  kdk.test:5100/v2/secure-group/tests/ruby-bundler/master/manifests/3bf5c8efcd276bf6133ccb787e54b7020a00b99c
```

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
  "config": {
    "mediaType": "application/vnd.docker.container.image.v1+json",
    "size": 7682,
    "digest": "sha256:b5c7d3594559132203ca916d26e969f7bf6492d2e80d753db046dff06a5303e6"
  },
  "layers": [
    {
        "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
        "size": 45342599,
        "digest": "sha256:e79bb959ec00faf01da52437df4fad4537ec669f60455a38ad583ec2b8f00498"
    },
    "..."
```

##### Get content of image layer

```shell
curl --cacert registry_host.crt -H "Authorization: Bearer $KHULNASOFT_REGISTRY_JWT" \
  kdk.test:5100/v2/secure-group/tests/ruby-bundler/master/blobs/sha256:e79bb959ec00faf01da52437df4fad4537ec669f60455a38ad583ec2b8f00498
```

### Using a custom Docker image as the main pipeline build image

It's possible to use the local KhulnaSoft container registry as the source of the build image in
pipelines.

1. Create a new project called `custom-docker-image` with the following `Dockerfile`:

   ```dockerfile
   FROM alpine
   RUN apk add --no-cache --update curl
   ```

1. Build and tag an image from within the same directory as the `Dockerfile` for the project.

   ```shell
   docker build -t kdk.test:5100/custom-docker-image .
   ```

1. Push the image to the registry. (See [Configuring the KhulnaSoft Docker runner to automatically pull images](#configuring-the-gitlab-docker-runner-to-automatically-pull-images) for the preferred method which doesn't require you to constantly push the image after each change.)

   ```shell
   docker push kdk.test:5100/custom-docker-image
   ```

   You should follow the directions given in the [Configuring the KhulnaSoft Docker runner to automatically pull images](#configuring-the-gitlab-docker-runner-to-automatically-pull-images) section to avoid pushing images altogether.

1. Create a `.gitlab-ci.yml` and add it to the Git repository for the project. Configure the `image` directive in the `.gitlab-ci.yml` file to reference the `custom-docker-image` which was tagged and pushed in previous steps:

   ```yaml
   image: kdk.test:5100/custom-docker-image

   stages:
     - test

   custom_docker_image_job:
     allow_failure: false
     script:
       - curl -I httpstat.us/201
   ```

1. The CI job should now pass and execute the `curl` command which we previously added to our base image:

   ```shell
   # CI job log output
   curl -I httpstat.us/201

   HTTP/1.1 201 Created
   ```

### Configuring the KhulnaSoft Docker runner to automatically pull images

In order to avoid having to push the Docker image after every change, it's
possible to configure the KhulnaSoft Runner to automatically pull the image
if it isn't present. This can be done by setting `pull_policy = "if-not-present"`
in the Runner's config.

```toml
# ~/.gitlab-runner/config.toml

[[runners]]
  name = "docker-executor"
  url = "http://kdk.test:3000/"
  token = "<my-token>"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.docker]
    image = "ruby:2.6.3"
    privileged = true
    # When the if-not-present pull policy is used, the Runner will first check if the image is present locally.
    # If it is, then the local version of image will be used. Otherwise, the Runner will try to pull the image.
    pull_policy = "if-not-present"
```

### Building and pushing images to your local KhulnaSoft container registry in a build step

It's sometimes necessary to use the local KhulnaSoft container registry in a pipeline. For
example, the [container scanning](https://docs.gitlab.com/ee/user/application_security/container_scanning/#example)
feature requires a build step that builds and pushes a Docker image to the registry before it can analyze the image.

To add a custom `build` step as part of a pipeline for use in later jobs
such as container scanning, add the following to your `.gitlab-yml.ci`:

```yaml
image: docker:stable

services:
  - name: docker:stable-dind
    command: ["--insecure-registry=kdk.test:5100"] # Only required if the registry is insecure

stages:
  - build

build:
  stage: build
  variables:
    DOCKER_TLS_CERTDIR: ""
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
    - docker pull $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA || true
    - docker build -t $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
```

To verify that the build stage has successfully pushed an image to your local KhulnaSoft container registry, follow the instructions in the section [List tags for a specific image](#list-tags-for-a-specific-image).

**Some notes about the above `.gitlab-yml.ci` configuration file:**

- The variable `DOCKER_TLS_CERTDIR: ""` is required in the `build` stage because of a breaking change introduced by Docker 19.03, described [here](https://about.gitlab.com/2019/07/31/docker-in-docker-with-docker-19-dot-03/).
- It's only necessary to set `--insecure-registry=kdk.test:5100` for the `docker:stable-dind` if you have not set up a [trusted self-signed registry](#set-up-pushing-and-pulling-of-images-over-https).

### Pushing multi-arch images to local KhulnaSoft container registry

1. Install [buildx](https://github.com/docker/buildx?tab=readme-ov-file#installing) for Docker.
1. Optional. If you are using Colima, [link the Colima socket](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md#cannot-connect-to-the-docker-daemon-at-unixvarrundockersock-is-the-docker-daemon-running) to the default socket path:

   ```shell
   sudo ln -sf $HOME/.colima/default/docker.sock /var/run/docker.sock
   ```

   > [!note]
   > Run `colima start` and create this symlink whenever you restart your computer.

1. If your local registry does not use HTTPS, add the following to `~/.docker/buildx/buildkitd.default.toml`. Create the file if it doesn't exist:

   ```toml
   [registry."registry.test:5100"]
     http = true
     insecure = true
   ```

1. Create a new [builder](https://docs.docker.com/build/builders/manage/#create-a-new-builder) for Docker that uses the `~/.docker/buildx/buildkitd.default.toml` configuration file from step `3` above:

   ```shell
   docker buildx create --name multi-arch-builder --config ~/.docker/buildx/buildkitd.default.toml
   ```

1. Run the following commands:

   1. Pull the multi-arch image:

      ```shell
      docker pull alpine:latest
      ```

   1. Tag the multi-arch image so you can push it to your local registry:

      ```shell
      docker tag alpine:latest registry.test:5100/path/to/project:platform-specific
      ```

   1. Push a single-architecture image from the multi-arch image that matches your host machine architecture:

      ```shell
      docker push registry.test:5100/path/to/project:platform-specific
      ```

   1. Push a multi-arch image to the local registry:

      ```shell
      docker buildx imagetools create --builder=multi-arch-builder --tag registry.test:5100/path/to/project:multi-arch alpine:latest
      ```

### Running container scanning on a local Docker image created by a build step in your pipeline

It's possible to use a `build` step to create a custom Docker image and then execute a
[container scan](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning) against this newly
built Docker image. This can be achieved by using the following `.gitlab-ci.yml`:

```yaml
include:
  template: Container-Scanning.gitlab-ci.yml

image: docker:stable

services:
  - name: docker:stable-dind
    command: ["--insecure-registry=kdk.test:5100"] # Only required if the registry is insecure

stages:
  - build
  - test

build:
  stage: build
  variables:
    DOCKER_TLS_CERTDIR: ""
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
    - docker pull $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA || true
    - docker build -t $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA

container_scanning:
  variables:
    CS_REGISTRY_INSECURE: "true" # see note below for discussion
```

> [!note]
> The contents of the above `.gitlab-ci.yml` file differs depending on how the container registry has been configured:

1. When the local container registry is insecure because `registry.self_signed: false` has been
   configured, the above `.gitlab-ci.yml` file can be used.

   It's necessary to set `CS_REGISTRY_INSECURE: "true"` in the `container_scanning` job for the
   KhulnaSoft Container Scanning tool ([`gcs`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/))
   to fetch the image from our registry using `HTTPS`, meanwhile our registry is running insecurely over `HTTP`.
   Setting the `CS_REGISTRY_INSECURE` as documented [here](https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables),
   forces `gcs` to use `HTTP` when fetching the container image from our insecure registry.

1. When the registry is secure because `registry.self_signed: true` has been configured, but we
   haven't referenced the self-signed certificate, then the following `services` and
   `container_scanning` sections of the above `.gitlab-ci.yml` must be used (the rest of the file
   has been omitted for brevity):

   ```yaml
   services:
     - docker:stable-dind

   container_scanning:
     variables:
       CS_DOCKER_INSECURE: "true"
   ```

   Since the local container registry is now running securely over an `HTTPS` connection, we no longer need to use `CS_REGISTRY_INSECURE: "true"`. However, we need to set the `CS_DOCKER_INSECURE: "true"` option to instruct `gcs` to accept a self-signed certificate.

1. When the registry is secure because `registry.self_signed: true` has been configured, **and** we
   reference the self-signed certificate, then the following `services` and `container_scanning`
   sections of the above `.gitlab-ci.yml` must be used (the rest of the file has been omitted for
   brevity):

   ```yaml
   services:
     - docker:stable-dind

   container_scanning:
     variables:
       ADDITIONAL_CA_CERT_BUNDLE: "-----BEGIN CERTIFICATE----- certificate-goes-here -----END CERTIFICATE-----"
   ```

   By configuring the `ADDITIONAL_CA_CERT_BUNDLE`, this instructs `gcs` to use the provided certificate when accessing the local container registry. Normally, the `ADDITIONAL_CA_CERT_BUNDLE` would be [configured in the UI](https://docs.gitlab.com/ee/ci/variables/#create-a-custom-variable-in-the-ui), but it's displayed here in the `.gitlab-ci.yml` for demonstration purposes.

### Switching Between `docker-desktop-on-mac` and `docker-machine`

To determine if you're using `docker-machine`, execute the following command:

```shell
export | grep -i docker

DOCKER_CERT_PATH=~/.docker/machine/machines/default
DOCKER_HOST=tcp://192.168.99.100:2376
DOCKER_MACHINE_NAME=default
DOCKER_TLS_VERIFY=1
```

If a list of environment variables are returned as above, this means that you're currently using `docker-machine` and any `docker` commands are routed to the virtual machine controlled by `docker-machine`.

To switch from `docker-machine` to `docker-desktop-for-mac`, simply unset the above environment variables:

```shell
unset DOCKER_CERT_PATH DOCKER_HOST DOCKER_MACHINE_NAME DOCKER_TLS_VERIFY
```

### Using a Development Version of the Container Registry

To test development versions of the container registry against KDK:

1. Within the [container registry](https://gitlab.com/gitlab-org/container-registry) project root, create a branch with your changes, for example a branch called `registry_dev`.

1. Under the `registry` section in your `kdk.yml` file, make sure that `version` is set to the branch name (e.g. `registry_dev`). You can do this by running `kdk config set registry.version registry_dev`.

1. Reconfigure and Restart KDK:

   ```shell
   kdk reconfigure
   kdk restart
   ```

1. Inspect the logs to confirm that the development version of the registry is running locally:

   ```shell
   kdk tail registry
   ```

  Verify the logs have a field: `"version":"registry-dev"`:

   ```plaintext
   2024-09-26_21:36:36.51052 registry              : {"go_version":"go1.22.0","instance_id":"2b3c8aba-4214-4f97-988b-21b6043e08be","level":"info","msg":"listening on [::]:5100","time":"2024-09-26T15:36:36.510-06:00","version":"registry-dev"}
   ```

### Use local KhulnaSoft container registry with AutoDevops pipelines

When testing AutoDevops pipelines with a local registry, you can receive errors in the build step:

- If a registry with self-signed certificate is used:

  ```shell
  $ /build/build.sh
  Logging to KhulnaSoft Container Registry with CI credentials...
  Error response from daemon: Get https://kdk.test:5100/v2/: x509: certificate signed by unknown authority
  ERROR: Job failed: command terminated with exit code 1
  ```

- If a registry with insecure registry is used:

  ```shell
  $ /build/build.sh
  Logging to KhulnaSoft Container Registry with CI credentials...
  Error response from daemon: Get https://kdk.test:5100/v2/: http: server gave HTTP response to HTTPS client
  ERROR: Job failed: command terminated with exit code 1
  ```

To fix such issues, you can customize your `build` job as a part of an AutoDevOps pipeline,
by adding the following to your `.gitlab-ci.yml`:

```yaml
include:
  - template: Auto-DevOps.gitlab-ci.yml

build:
  services:
    - name: docker:stable-dind
      # Only required if the registry is insecure or used self signed certificate
      command: ["--insecure-registry=kdk.test:5100"]
```

And for example, if you have minikube as a Kubernetes runner
and you configured a self-signed registry, you can add a generated certificate to Docker inside of minikube:

1. Run the following on your KDK instance:

   ```shell
   $ cat ~/.docker/certs.d/kdk.test\:5100/ca.crt
   -----BEGIN CERTIFICATE-----
   ...
   -----END CERTIFICATE-----
   ```

1. Copy this certificate to minikube:

   ```shell
   $ minikube ssh
   $ sudo mkdir -p /etc/docker/certs.d/kdk.test\:5100
   $ sudo tee /etc/docker/certs.d/kdk.test\:5100/ca.crt > /dev/null <<EOT
   -----BEGIN CERTIFICATE-----
   ...
   -----END CERTIFICATE-----
   EOT
   $ sudo systemctl restart docker
   $ logout
   ```

Or if you are using insecure registry, you can run minikube with command like:

```shell
minikube start --insecure-registry="kdk.test:5100"
```

Then the AutoDevOps pipeline should be able to build images and run them inside of Kubernetes.

### Notifications

Some KhulnaSoft features, such as calculating the [storage usage](https://docs.gitlab.com/ee/user/usage_quotas.html) of the Container Registry images, requires the
[Container Registry Notifications](https://docker-docs.uclv.cu/registry/notifications/) to be enabled. When enabled, upon different events, such as pushing a container image, the
Container Registry sends a notification to the Rails backend.

To enable Container Registry notifications, update the `kdk.yml` file as follows:

```yaml
registry:
  # ... other options
  notifications_enabled: true
```

Then run `kdk reconfigure`.

Now, [pushing](#push-the-image-to-the-local-registry) an image to the Container Registry triggers a request to the `/api/v4/container_registry_event/events` route
in the Rails backend.

### Metadata Database

The [Container Registry uses a PostgreSQL database](https://docs.gitlab.com/ee/administration/packages/container_registry_metadata_database.html)
to enable features like online garbage collection.

To use the Container Registry metadata database, you can either:

- Import your existing container repositories from the older registry.
- Use a new registry with no prior repositories.

#### Before you begin

- After you enable the database, you must continue to use it. The database becomes the source of the
  registry metadata. If you disable the database, the registry loses visibility of all images written
  to it when the database was active.

- Do not manually run offline garbage collection after the import step is complete. This action deletes
  data because it is not compatible with the registries using the metadata database.

- Before you import data to the new registry, back up important data in your current registry.

#### Use a new registry

To use the Container Registry metadata database with a new registry:

1. In `kdk.yml`, add:

   ```yaml
   registry:
     # ... other options
     database:
       enabled: true
   ```

1. Reconfigure KDK by using the `kdk reconfigure` command.

1. Restart the registry using the `kdk restart registry` command.

#### Use existing registries

To import existing repositories into the new metadata database registry:

1. Stop the existing registry if it is running by using the `kdk stop registry` command.

1. Update the `kdk.yml` file:

   ```yaml
   registry:
     # ... other options
     read_only_maintenance_enabled: true
     database:
       enabled: false
   ```

1. Run the following commands:

   ```shell
   kdk reconfigure
   kdk import-registry-data
   ```

   Wait until the `registry import complete` log appears.

1. Update `kdk.yml` again:

   ```yaml
   registry:
     # ... other options
     # read_only_maintenance_enabled: false (remove or set to false )
     database:
       enabled: true
   ```

1. Reconfigure KDK by using the `kdk reconfigure` command.

1. Restart the registry using the `kdk restart registry` command.

#### Reset registry database

To clean up existing Registry PostgreSQL data and reinstate a fresh registry database:

1. Run the following command:

   ```shell
   kdk reset-registry-data
   ```

### Troubleshooting

#### Missing container repositories in the UI

The container registry UI may only show one repository even after pushing two or more repositories.
This may happen if authentication between the registry and KhulnaSoft is disabled (`auth_enabled: false`).
To enable authentication follow these steps:

1. Under the `registry` section in your `kdk.yml` file, make sure that `auth_enabled` is set to `true`:

   ```yaml
   registry:
     auth_enabled: true
   ```

1. Run `kdk reconfigure`.
1. Run `kdk restart`.
1. Navigate to your project's **Container Registry** page and verify more images show up in the UI.
