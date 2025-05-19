---
title: KhulnaSoft AI Gateway
---

Configure the [KhulnaSoft AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
to run locally in KDK.

This installation method is a simpler alternative to
[manually cloning, installing, and running the AI Gateway locally](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist#how-to-run-the-server-locally).

## Prerequisites

- Access to [Google Cloud](#set-up-google-cloud-platform-in-ai-gateway).
- Access to [Anthropic API](#set-up-anthropic-in-the-ai-gateway).
- AI Gateway [tool dependencies](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.tool-versions).

## Set up the AI Gateway

1. Run this Rake task from your KDK root directory and follow the prompts:

   ```shell
   rake setup_ai_gateway
   ```

   The prompts are:

   1. **Enter your Anthropic API key**: The key you enter will be used to authenticate requests to Anthropic's AI services. It's essential for accessing their API and using their AI models.
   1. **Set additional environment variables for debugging**: It will set additional environment variables that provide more detailed logs and information, useful for troubleshooting and development.
   1. **Enable AI Gateway in SaaS**: Option to enable the AI Gateway in a SaaS configuration. If you answer no (`N`), the KDK runs in self-managed mode.
   1. **Enable hot reload**: It will enable hot reloading, which allows the application to update in real-time as you make code changes, without requiring a full restart.

   > [!note]
   > If you update steps or documentation for setting up AI Gateway, check and update this Rake task as well if necessary.

   You can watch the status of the service by running `kdk tail gitlab-ai-gateway`.

   To check if your monolith is using the correct URL after restarting, run `bundle exec rake cache:clear` and then visit `http://<your-kdk-url>/help/instance_configuration#ai_gateway_url`.

   > [!note]
   > When you access the AI Gateway URL directly, you'll see a `{"error":"No authorization header presented"}` error message. This is expected and doesn't affect the usage of AI features locally in KDK.
   > You can [bypass authentication](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/auth.md#bypass-authentication-and-authorization-for-testing-features) by modifying the AI Gateway's environment configuration, but this should only be done for using the OpenAPI playground. Make sure to revert any authentication bypass changes before pushing to production.

1. Go to the [AI Gateway OpenAPI playground](http://localhost:5052/docs)
   to verify that your local AI Gateway started successfully.

1. Continue with the instructions for setting up KhulnaSoft Duo features to [set up an Ultimate license for your KDK](https://docs.gitlab.com/ee/development/ai_features/index.html#required-setup-licenses-in-gitlab-rails).

## Additional AI Gateway troubleshooting and configuration

### Change the AI Gateway URL

You must tell your local KhulnaSoft instance to talk to your local AI
Gateway. Otherwise, your instance tries to talk to the production AI Gateway
at `cloud.gitlab.com`, which results in an `A1001` error.

By default, the AI Gateway lives at `localhost:5052/docs`.

You can host the AI Gateway at a different URL by updating the following values in the [application settings file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/application_settings.md):

```shell
# <KDK-root>/gitlab-ai-gateway/.env

AIGW_FASTAPI__API_HOST=0.0.0.0
AIGW_FASTAPI__API_PORT=5052
```

To check if your KDK repo is using the correct AI Gateway, go to `http://<your-kdk-url>/help/instance_configuration#ai_gateway_url`. This value is cached so you may need to run `bundle exec rake cache:clear` to see the latest value.

### Set up Google Cloud Platform in AI Gateway

If you do not set up Google Cloud Platform (GCP) correctly, you might not be able to boot AI Gateway because AI Gateway checks the GCP credentials and access at boot time.

To set up GCP, you can do either of the following:

- Use the existing project.
- Create a sandbox project.

#### Use the existing project

You can use the existing `ai-enablement-dev-69497ba7` Google Cloud project.

You should use this project:

- Because it has Vertex APIs and Vertex AI Search already enabled.
- If you are a KhulnaSoft team member. Members from the Engineering and Product divisions
  should already have access to this project.

To check if you have access to this existing project, go to the [Google Cloud console](https://console.cloud.google.com).

If you do not have access, complete the [GCP access request template](https://gitlab.com/gitlab-com/it/infra/issue-tracker/-/issues/new?issuable_template=gcp_group_account_iam_update_request).

#### Create a sandbox Google Cloud project

Prerequisites:

- Install the [`gcloud` CLI](https://cloud.google.com/sdk/docs/install).
- Optional. If you use [`mise`](mise.md) for runtime version
  management, install `gcloud` with the [`asdf gcloud` plugin](https://github.com/jthegedus/asdf-gcloud).

To create a sandbox Google Cloud project:

1. Authenticate locally with Google Cloud using [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login).
1. Update the [application settings file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/application_settings.md) in AI Gateway:

   ```shell
   # <KDK-root>/gitlab-ai-gateway/.env

   # PROJECT_ID = "ai-enablement-dev-69497ba7" for KhulnaSoft team members with access
   # to the shared project. This should be set by default

   # PROJECT_ID = "your-google-cloud-project-name" for those with their own sandbox
   # Google Cloud project.

   AIGW_GOOGLE_CLOUD_PLATFORM__PROJECT='PROJECT_ID'
   ```

1. [Create a sandbox project](https://handbook.gitlab.com/handbook/infrastructure-standards/#individual-environment).

If you are using an individual Google Cloud project, because some of the [KhulnaSoft Duo features](https://docs.gitlab.com/ee/user/khulnasoft_duo/) use the Vertex AI API, you might also have to enable the Vertex AI API:

   1. Go to the [Google Cloud welcome page](https://console.cloud.google.com/welcome).
   1. Choose your project (for example: `jdoe-5d23dpe`).
   1. Select **APIs & Services > Enabled APIs & services**.
   1. Select **Enable APIs and Services**.
   1. Search for `Vertex AI API`.
   1. Select **Vertex AI API**, then select **Enable**.
   1. Authenticate locally with Google Cloud:
      - Use the [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login)
      command if your Application Default Credentials (ADC) account has the `serviceusage.services.use` permission on the quota project
      from GCloud's context.
      - Use the `gcloud auth application-default login --disable-quota-project` command if you:
      - Do not have a project with the `serviceusage.services.use` permission.
      - Want to always bill the project owning the resources.

### Set up Anthropic in the AI Gateway

You must set up Anthropic because some KhulnaSoft Duo features use Anthropic models.

1. Complete an [access request](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/new?description_template=Access_Change_Request).
1. Sign up for an Anthropic account and [create an API key](https://docs.anthropic.com/en/docs/getting-access-to-claude).
1. Update the [application settings file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/application_settings.md) in AI Gateway:

   ```shell
   # <KDK-root>/gitlab-ai-gateway/.env

   ANTHROPIC_API_KEY='<your-anthropic-api-key>'
   ```

### Optional: Enable logging in AI Gateway

Logging makes it easier to debug any issues with KhulnaSoft Duo requests.

To enable logging, update the [application settings file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/application_settings.md) in AI Gateway:

```shell
# <KDK-root>/gitlab-ai-gateway/.env

AIGW_LOGGING__LEVEL=debug
AIGW_LOGGING__FORMAT_JSON=false
AIGW_LOGGING__TO_FILE='./ai-gateway.log'
```

For example, you can watch the log file with the following command when in the
`gitlab-ai-gateway` directory:

```shell
# <KDK-root>/gitlab-ai-gateway

tail -f ai-gateway.log | fblog -a prefix -a suffix -a current_file_name -a suggestion -a language -a input -a parameters -a score -a exception
```

### Optional: Run a different branch of AI Gateway and Duo Workflow Service

The
[AI Gateway repository](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)
is cloned into `<kdk-dir>/gitlab-ai-gateway`.

To configure KDK to run a specific branch, use either the branch name or SHA:

```shell
kdk config set khulnasoft_ai_gateway.version <branch-name-or-SHA>
kdk reconfigure
```

## Error: `Activated Python version 3.XX.X is not supported`

The Rake task calls a makefile, [`Make.gitlab-ai-gateway.mk`](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/support/makefiles/Makefile.gitlab-ai-gateway.mk?ref_type=heads),
that installs dependencies defined in the AI Gateway [tool version file](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.tool-versions?ref_type=heads). The makefile will install Python version 3.10, but the system may return an error message if a different version of Python has been installed from a separate source:

```plaintext
The currently activated Python version 3.XX.X is not supported by the project (~3.10.0).
```

To resolve this issue, you should install the following dependency versions with `mise`:

```shell
mise install python 3.10.14
```
