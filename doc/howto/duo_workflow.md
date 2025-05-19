---
title: Duo Workflow
---

## Prerequisites

1. Setup [AI Gateway](khulnasoft_ai_gateway.md).
1. Install the [`gcloud` CLI](https://cloud.google.com/sdk/docs/install) and configure it with a suitable project:

   ```shell
   gcloud auth application-default login
   ```

1. Configure a [loopback interface](local_network.md#create-loopback-interface) to enable the executor to access services from Docker containers. The loopback adapter automatically becomes the host for the Duo Workflow Service.
   - If you are using Colima, configure it to use your loopback IP address:

       ```shell
       colima stop
       colima start --network-address=true --dns-host kdk.test=<LOOPBACK_IP_ADDRESS>
       ```

1. Create a project in a group with experimental features and KhulnaSoft Duo turned on:
   1. Create or update a group by running the following [Rake task](https://docs.gitlab.com/ee/development/ai_features/#option-a-in-saas-gitlabcom-mode) in your KhulnaSoft repository directory:

      ```shell
      KHULNASOFT_SIMULATE_SAAS=1 bundle exec 'rake gitlab:duo:setup[test-group-name]'
      ```

   1. Create a project in the group.

## Configure Duo Workflow components

1. In the root of your `<kdk-dir>` enable `duo_workflow` and configure your KhulnaSoft instance to use this locally running instance:

   ```shell
   kdk config set duo_workflow.enabled true
   kdk reconfigure
   kdk restart duo-workflow-service rails
   ```

   The source code of Duo Workflow Service is located at `<kdk-dir>/gitlab-ai-gateway/duo_workflow_service`.

1. Configure VS Code to use Docker by following the instructions in the [Duo Workflow user documentation](https://docs.gitlab.com/ee/user/duo_workflow/index.html#install-docker-and-set-the-socket-file-path).
1. Add a project to your VS Code workspace.
   - The project should be in a group with experimental features and KhulnaSoft Duo turned on, as described in the Prerequisites section above.
   - Make sure it is the only repository open in the Source Control panel.

You can now [use Duo Workflow in VS Code](https://docs.gitlab.com/ee/user/duo_workflow/index.html#use-gitlab-duo-workflow-in-vs-code).

## Optional: Run a different branch of Duo Workflow Service

See [Run a different branch of AI Gateway and Duo Workflow Service](khulnasoft_ai_gateway.md#optional-run-a-different-branch-of-ai-gateway-and-duo-workflow-service).

## Optional: Run a different branch of Duo Workflow Executor

The [`duo-workflow-executor` repository](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor) is
cloned into `<kdk-dir>/duo-workflow-executor` and compiled every time you run
`kdk reconfigure`. The binary is placed in `<kdk-dir>/gitlab/public/assets` and
served up by your local KhulnaSoft instance.

To change the version used:

1. Edit the `<kdk-dir>/gitlab/DUO_WORKFLOW_EXECUTOR_VERSION` with a valid SHA in the repository.
1. Recompile the binary:

   ```shell
   kdk reconfigure
   ```

## Optional: Configure LLM Cache

LLMs are slow and expensive. If you are doing lots of repetitive development
with Duo Workflow you may wish to enable
[LLM caching](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-service#llm-caching)
to speed up iteration and save money. To enable the cache:

```shell
kdk config set duo_workflow.llm_cache true
kdk reconfigure
kdk restart duo-workflow-service rails
```
