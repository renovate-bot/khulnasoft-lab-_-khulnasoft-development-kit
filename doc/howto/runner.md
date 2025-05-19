---
title: Using KhulnaSoft Runner with KDK
---

Most features of [KhulnaSoft CI/CD](http://docs.gitlab.com/ee/ci/) need a
[runner](https://docs.gitlab.com/runner/) to be registered with
the KhulnaSoft installation. This how-to takes you through the necessary steps to
do so when KhulnaSoft is running under KDK.

Before setting up a runner, you must have [set up the KDK](../_index.md) for your workstation.

The KDK supports managing the runner configuration file and the process itself, either with a native binary
or within a Docker container. Running jobs inside a Docker executor is supported in both cases; you can use a native
binary to run jobs inside a Docker container.

You can set up a runner to execute using either of the following approaches:

- [Directly on your workstation](#executing-a-runner-directly-on-your-workstation)
- [From within Docker](#executing-a-runner-from-within-docker) (recommended)

> [!note]
> In the configuration examples, `runner` should not be confused with [`khulnasoft_runner`](khulnasoft_docs.md).

## Executing a runner directly on your workstation

### Download KhulnaSoft Runner

Before you register a runner in your KDK, you first must have a runner binary either:

- Pre-built. To use a pre-built binary, follow [the runner installation instructions](https://docs.gitlab.com/runner/install/#binaries)
  for your specific operating system. Avoid following the instructions in the **Containers** section, as it's simpler
  to let the KDK manage the runner process.
- Compiled from source. To build from source, follow [the runner development instructions](https://docs.gitlab.com/runner/development/).
  See the official [KhulnaSoft Runner repository](https://github.com/khulnasoft-lab/khulnasoft-runner).

By default, KDK expects the runner binary to be at `/usr/local/bin/gitlab-runner`. To specify a custom `gitlab-runner`
binary location, add the following to `kdk.yml`:

```yaml
runner:
  bin: <path_to_khulnasoft_runner_binary>/gitlab-runner-darwin-amd64
```

### Create and register a local runner

To create and register a local runner for your instance:

1. On the left sidebar, click on the `Search or go to...` button.
1. Select **Admin Area**.
1. On the left sidebar, select **CI/CD > Runners**.
1. Select **New instance runner**.
1. In the **Tags** section, select the **Run untagged** checkbox. Tags specify which jobs
   the runner can run. Tags are optional, but if you don't specify tags then you must specify
   that the runner can run untagged jobs.
1. Optional. If you have specific jobs you want the runner to run, in the **Tags** field, enter
   comma-separated tags.
1. Optional. Enter additional runner configurations.
1. Select **Create runner**.
1. Select an operating system.
1. Follow the on-screen instructions to register the runner from the command-line:

     ```shell
     gitlab-runner register \
       --url "<KDK URL>" \
       --token <TOKEN>
     ```

    If your `gitlab-runner` configuration file is stored in a different location than `~/.gitlab-runner/config.toml`, then you must use the `--config` option to specify the location of the file:

     ```shell
     gitlab-runner register \
       --url "<KDK URL>" \
       --token <TOKEN> \
       --config <path-to-kdk>/gitlab-runner-config.toml
     ```

   When prompted:
   - For `executor`, use either `shell` or `docker`:

      - `shell`. If you intend to run simple jobs, use the `shell` executor. Builds run directly on the host computer.
         If you choose this configuration, don't use random `.gitlab-ci.yml` files from the internet unless you
         understand them fully as this could be a security risk. If you need a basic pipeline, see an
         [example configuration from our documentation](https://docs.gitlab.com/ee/ci/environments/#configure-manual-deployments)
         that you can use.

      - `docker`

        - **Enter the default Docker image**: Provide a Docker image to use to run the job if no image is provided in a job
            definition.

          You'll also need to install some additional supporting packages.

          The following instructions are for Mac OS.

          1. <details><summary>Option 1: Use Colima</summary>

             1. Install both `docker` and `colima`, and start the `colima` process:

                ```shell
                brew install docker colima
                colima start
                ```

             1. Create a new [Docker context](https://docs.docker.com/engine/manage-resources/contexts/)
                for Colima.

                ```shell
                docker context create <context-name> --docker "host=unix://$HOME/.colima/default/docker.sock"
                ```

             1. Activate the new context.

                ```shell
                docker context use <context-name>
                ```

             1. Verify the new Docker context is active.

                ```shell
                docker context ls
                ```

                The terminal returns a list of all available contexts.
                Ensure the new context is marked as active.
             </details>

          1. <details><summary>Option 2: Use Rancher Desktop</summary>

             1. [Install Rancher Desktop](https://rancherdesktop.io/).
             1. Start Rancher Desktop
             1. Set the required `docker_host` context for the runner:

                ```shell
                kdk config set runner.docker_host "unix://$HOME/.rd/docker.sock"
                ```

             </details>

   - For `KhulnaSoft instance URL`, use`http://localhost:3000/`, or `http://<custom_IP_address>:3000/`
     if you customized your IP address.
1. Start your runner:

   ```shell
   gitlab-runner run --config <path-to-kdk>/gitlab-runner-config.toml
   ```

After you register the runner, the configuration and the authentication token are stored in
`gitlab-runner-config.toml`, which is in KDK's `.gitignore` file.

To ensure the runner token persists between subsequent runs of `kdk reconfigure`, add the
authentication token from `gitlab-runner-config.toml` to your `kdk.yml` file and set `executor` to `shell`:

```yaml
runner:
  enabled: true
  executor: shell
  token: <runner-token>
```

Finally, run `kdk update` to rebuild your `Procfile`. This allows you to manage the runner along with your other KDK processes.

Alternately, run `gitlab-runner --log-level debug run --config <path-to-kdk>/gitlab-runner-config.toml`
to get a long-lived runner process, using the configuration you created in the
last step. It stays in the foreground, outputting logs as it executes
builds, so run it in its own terminal session.

The **Runners** page (`/admin/runners`) now lists the runners. Create a project in the KhulnaSoft UI and add a
[`.gitlab-ci.yml`](https://docs.gitlab.com/ee/ci/examples/) file,
or clone an [example project](https://gitlab.com/groups/gitlab-examples), and
watch as the runner processes the builds just as it would on a "real" install!

## Executing a runner from within Docker

Instead of running KhulnaSoft Runner locally on your workstation, you can run it using Docker. This approach allows you to
get an isolated environment for a job to run in.

That prevents the job from interfering with your local workstation environment, and vice versa. It is safer than running
directly on your computer, as the runner does not have direct access to your computer.

To set up KhulnaSoft Runner to run in a Docker container:

1. [Set up a local network](#set-up-a-local-network) - preferably to run KDK on `http://kdk.test:3000`.
1. [Set up a runner](#set-up-a-runner). You need to generate a runner configuration file.
1. [Set up KDK to use the registered runner](#set-up-kdk-to-use-the-registered-runner). Configure KDK to manage a Docker
   runner.

### Set up a local network

To use the Docker configuration for your runner:

1. Make sure your KDK **DOES NOT** run on the default `localhost` or `127.0.0.1` address, because it clashes with the
   routing inside a Docker container, so a runner or job isn't able to reach your KDK and fails with `connection refused`
   error.

   To avoid this problem, [Create a loopback interface](local_network.md#create-loopback-interface).

1. Verify that you're able to run KDK on the `kdk.test` domain listening to an IP **OTHER THAN** `127.0.0.1`. If you
   followed the instructions in the previous step, it is `172.16.123.1`.

### Set up a runner

When you have KDK running on something like `http://kdk.test:3000`, you can set up a runner. KDK can manage a
containerized runner for you.

[Create a runner](#create-and-register-a-local-runner), which generates the runner token you need before you can
register the runner.

To [register a runner](https://docs.gitlab.com/runner/register/index.html#docker) in your KDK, you can run the
`gitlab/gitlab-runner` Docker image. You **must ensure** that the runner saves the configuration to a file that is
accessible to the host after the registration is complete.

In these instructions, we use a location known to KDK so that KDK can manage the configuration. Docker doesn't know about the custom host name `kdk.test`, so you must use
`--add-host` and `--docker-extra-hosts` to add the host to IP mapping for this address.

To register a runner, run the following command in the root for your KDK directory:

```shell
docker run --rm -it --add-host kdk.test:172.16.123.1 -v $(pwd)/tmp/gitlab-runner:/etc/gitlab-runner gitlab/gitlab-runner register --url "http://kdk.test:3000" --token <runner-token> --config /etc/gitlab-runner/gitlab-runner-config.toml --docker-extra-hosts kdk.test:172.16.123.1
```

<details>
<summary>Option for SSL users (expand)</summary>

If you have [SSL enabled with NGINX](nginx.md), a Docker-based runner must have access to your self-signed
certificate (for example, `kdk.test.pem`). Your certificate is automatically converted from `pem` to `crt`. KDK
automatically mounts your certificate into the Docker container when you start the runner, but you must include the certificate
manually when registering your runner:

```shell
docker run --rm -it -v "$(pwd)/kdk.test.pem:/etc/gitlab-runner/certs/kdk.test.crt" -v $(pwd)/tmp/gitlab-runner:/etc/gitlab-runner gitlab/gitlab-runner register --url <kdk-url> --token <runner-token> --config /etc/gitlab-runner/gitlab-runner-config.toml
```

</details>
<p>

The `register` subcommand requires the following information:

- **Enter the KhulnaSoft instance URL (for example, <https://gitlab.com/>)**: Use `http://kdk.test:3000/`, or `http://<custom_IP_address>:3000/` if you customized your IP
  address.
- **Enter a description for the runner** (optional): A description of the runner.
- **Enter an executor**: Because we are running our runner in Docker, choose `docker`.
- **Enter the default Docker image**: Provide a Docker image to use to run the job if no image is provided in a job
  definition. By default, KDK sets `alpine:latest`.

### Set up KDK to use the registered runner

Now when the runner is registered we can find the token in `<path-to-kdk>/tmp/gitlab-runner/gitlab-runner-config.toml`.
For example:

```shell
# grep token <path-to-kdk>/gitlab-runner-config.toml
token = "<runner-token>"
```

The KDK manages a runner in a Docker container for you, but it needs this token in your `kdk.yml` file. Edit the
`kdk.yml` to use this value and set `install_mode` and `executor` to `docker`. You should also set the `extra_hosts`
value as a:

- Hostname to the IP mapping you've used to register the runner (`kdk.test` from KDK instructions).
- Hostname you've set up for the registry (`registry.test` from KDK instructions).

For example:

```yaml
runner:
  enabled: true
  install_mode: docker
  executor: docker
  token: <runner-token>
  extra_hosts: ["kdk.test:172.16.123.1", "registry.test:172.16.123.1"]
```

<details>
<summary>Optional step for SSL users (expand)</summary>

For SSL users, the KDK configures the Docker runner with
[`tls_verify`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersdocker-section)
set to `false`, so SSL verification is disabled by
default.

</details>

To apply the settings:

1. Run `kdk reconfigure` to update `<path-to-kdk>/gitlab-runner-config.toml` with KDK-specific settings.
1. Run `kdk restart`.
1. Verify the runner is connected at `<gitlab-instance-url>/admin/runners`.

You should also be able to see the runner container up and running in `docker`:

```shell
docker ps
CONTAINER ID   IMAGE                         COMMAND                  CREATED              STATUS              PORTS     NAMES
c0ee80a6910e   gitlab/gitlab-runner:latest   "/usr/bin/dumb-init …"   About a minute ago   Up About a minute             festive_edison
```

From now on you can use `kdk start runner` and `kdk stop runner` CLI commands to start and stop your runner.

To customize the runner, you must configure through your `kdk.yml` file. Any customizations you make directly to the
`<path-to-kdk>/gitlab-runner-config.toml` file are overwritten when you run `kdk update`. To add support for more
runner customizations through `kdk.yml`, raise a merge request to update
[`lib/kdk/config.rb`](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/master/lib/kdk/config.rb).

You are good to go! Now you can assign the runner to a project and verify your jobs are running properly!

<details>
<summary>Here's how (expand):</summary>

1. Create a new project and ensure the new runner is available:
1. Add a `.gitlab-ci.yml` file like this one:

   ```yaml
   build-job:       # This job runs in the build stage, which runs first.
    stage: build
    script:
      - echo "Compiling the code..."
      - echo "Compile complete."
   ```

1. After you commit the `.gitlab-ci.yml` file, you can check if the CI job passed successfully in the `Jobs` section under the `CI/CD` folder in your project.

</details>

### Alternative method for Linux

An alternative to creating the dummy interface described above is to:

1. Add the following to your `kdk.yml`

   ```yaml
   runner:
     network_mode_host: true
   ```

1. Run `kdk reconfigure`

This will add `network_mode = host` to the `gitlab-runner-config.toml` file:

```toml
[[runners]]
  [runners.docker]
    ...
    network_mode = "host"
```

Note that this method:

- [Only works with Linux hosts](https://docs.docker.com/network/host/).
- Exposes your local network stack to the Docker container, which may be a security issue. Use
  it only to run jobs on projects that you trust.
- Won't work with Docker containers running in Kubernetes because Kubernetes uses its own
  internal network stack.

### Put it all together

At the end of all these steps, your config files should look something like this:

<details>
<summary>(expand)</summary>

`~/gitlab-runner/config.toml`

```toml
   concurrent = 1
   check_interval = 0

   [session_server]
     session_timeout = 1800

   [[runners]]
     name = "example description"
     url = "http://kdk.test:3000/"
     id = 1
     token = "<runner-token>"
     token_obtained_at = 2022-09-22T07:34:57Z
     token_expires_at = 0001-01-01T00:00:00Z
     executor = "docker"
     [runners.custom_build_dir]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
       [runners.cache.azure]
     [runners.docker]
       tls_verify = false
       image = "ruby:2.7"
       privileged = false
       disable_entrypoint_overwrite = false
       oom_kill_disable = false
       disable_cache = false
       volumes = ["/cache"]
       extra_hosts = ["kdk.test:172.16.123.1"]
       shm_size = 0
```

`kdk.yml`

```yaml
---
hostname: kdk.test
listen_address: 172.16.123.1
runner:
  enabled: true
  install_mode: docker
  executor: docker
  token: <runner-token>
  extra_hosts: ["kdk.test:172.16.123.1"]
```

</details>
<p>

### Troubleshooting tips

- In the KhulnaSoft Web interface, check `/admin/runners` to ensure that
  your runner has contacted the server. If the runner is there but
  offline, this suggests the runner registered successfully but is now
  unable to contact the server via a `POST /api/v4/jobs/request` request.
- Run `kdk tail runner` to look for errors.
- Check that the runner can access the hostname specified in `gitlab-runner-config.toml`.
- Select `Edit` on the desired runner and make sure the `Run untagged jobs` is unchecked. Runners
  that have been registered with a tag may ignore jobs that have no tags.
- Run `tail -f gitlab/log/api_json.log | grep jobs` to see if the runner is attempting to request CI jobs.

#### Docker Daemon Connection Failure

The following error usually indicates that your system cannot connect to the Docker daemon:

```plaintext
ERROR: Failed to remove network for build
ERROR: Preparation failed: Cannot connect to the Docker daemon at unix:///var/run/docker.sock.
Is the docker daemon running? (docker.go:803:0s)
```

<details>
<summary>Solutions</summary>

#### Solution 1: Verify your Docker context

You might need to adjust Docker to use the correct context.

1. Run this command to verify your current Docker context:

   ```shell
   docker context ls
   ```

1. If you're not in the correct context, run this command to switch:

   ```shell
   docker context use <context-name>
   ```

#### Solution 2: Set `DOCKER_HOST` to the Colima socket

You might need to set your `DOCKER_HOST` environment variable to the Colima socket.

1. Add this to your shell configuration file:

   ```shell
   export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
   ```

1. Reload your shell.

#### Solution 3: Configure the Docker socket in KhulnaSoft Runner

You might need to modify the KhulnaSoft Runner config file.

1. Run `docker context ls` and note the path to `docker.sock`.
1. Open the KhulnaSoft Runner config file `/Users/<username>/.gitlab-runner/config.toml`.
1. Under `[runners.docker]` add the following line:

   ```toml
   host = <path_to_docker.sock_file>
   ```

##### Solution 4: Link the Colima Socket to the Default Docker Socket Path

You can also try [linking the Colima socket](https://github.com/abiosoft/colima/blob/master/docs/FAQ.md#cannot-connect-to-the-docker-daemon-at-unixvarrundockersock-is-the-docker-daemon-running) to the default socket path:

```shell
sudo ln -sf $HOME/.colima/default/docker.sock /var/run/docker.sock
```

You must run `colima start` and create the above symlink every time you restart your device.

</details>
