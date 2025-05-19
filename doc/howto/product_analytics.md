---
title: Product Analytics
---

[Product Analytics](https://docs.gitlab.com/ee/user/product_analytics/) must be run locally in conjunction with the [Product Analytics DevKit](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit).

## Product Analytics DevKit setup

### Prerequisites

- You must have Docker (or equivalent) on your machine.

### Set up the Product Analytics DevKit

1. Follow the [instructions](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit#product-analytics-devkit) to set up the Product Analytics DevKit on your machine.
1. Continue following the [instructions](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit#connecting-kdk-to-your-devkit) to connect the KDK to the Product Analytics DevKit.

## KDK setup

### Prerequisites

- Your KDK instance must have an active license for KhulnaSoft Ultimate.
- For billing functionality, your KDK must [simulate a SaaS instance](https://docs.gitlab.com/ee/development/ee_features.html#simulate-a-saas-instance).

### One-line setup

To automatically set up Product Analytics, in your `gitlab` directory run the following command:

```shell
RAILS_ENV=development bundle exec rake gitlab:product_analytics:setup\['gitlab-org'\]
```

> [!note]
> You can replace `gitlab-org` with the group name you want to enable Product Analytics on.

After running the command [set up the DevKit](#set-up-the-product-analytics-devkit) if you haven't already done so.

Once set up, you can follow the [instructions](#onboarding-projects-to-product-analytics) below on how to onboard projects to product analytics.

### Manual setup

1. Enable the required [feature flags](#feature-flags).
1. Run KDK in [SaaS mode](https://docs.gitlab.com/ee/development/ee_features.html#simulate-a-saas-instance) with an Ultimate license.
1. Set the **Ultimate** plan on your test group.
1. Enable Experiment & Beta features on your test group.

   1. Go to **Settings > General**.
   1. Expand **Permissions and group features**.
   1. Enable **Experiment & Beta features** and **Product analytics**.
   1. Select **Save changes**.

1. [Set up the DevKit](#set-up-the-product-analytics-devkit) and connect it to your KDK.

Once set up, you can follow the [instructions](#onboarding-projects-to-product-analytics) below on how to onboard projects to product analytics.

### Onboarding projects to Product Analytics

Follow the [instructions](https://docs.gitlab.com/ee/user/product_analytics/#onboard-a-gitlab-project) to onboard a project with your Product Analytics.

For day-to-day local development, you can use the [self-managed provider](https://docs.gitlab.com/ee/user/product_analytics/?tab=Self-managed+provider#onboard-a-gitlab-project) 
option. To use the instance-level Product Analytics settings, make sure **Use instance-level settings** is selected.

For local development of the billing functionality, you should use the [KhulnaSoft-managed provider](https://docs.gitlab.com/ee/user/product_analytics/?tab=KhulnaSoft-managed+provider#onboard-a-gitlab-project)
option.

Once set up, you can follow the [instructions](#view-product-analytics-dashboards) below on how to view the product analytics dashboards.

### View Product Analytics dashboards

1. On the left sidebar, at the top, select **Search KhulnaSoft** (**{search}**) to find the project set up in the previous
   section.
1. On the left sidebar, select **Analyze > Analytics dashboards**.

## Feature flags

Product analytics features are behind feature flags and must be enabled to use them in KDK.

> [!note]
> The one-line setup command enables all product analytics related feature flags.

| Feature flag                                 | Default enabled | Introduced by                                                  |
|----------------------------------------------|-----------------|----------------------------------------------------------------|
| `product_analytics_admin_settings`           | `false`         | `https://github.com/khulnasoft-lab/khulnasoft/-/merge_requests/167192` |
| `product_analytics_features`                 | `false`         | `https://github.com/khulnasoft-lab/khulnasoft/-/merge_requests/167296` |
| `product_analytics_billing`                  | `true`          | `https://github.com/khulnasoft-lab/khulnasoft/-/merge_requests/141624` |
| `product_analytics_billing_override`         | `false`         | `https://github.com/khulnasoft-lab/khulnasoft/-/merge_requests/148991` |
| `product_analytics_usage_quota_annual_data`  | `false`         | `https://github.com/khulnasoft-lab/khulnasoft/-/merge_requests/136932` |
| `generate_cube_query`                        | `false`         | `https://github.com/khulnasoft-lab/khulnasoft/-/merge_requests/140107` |

To enable a feature flag, run:

```shell
echo "Feature.enable(:FEATURE_FLAG_NAME)" | kdk rails c
```

To disable a feature flag, run:

```shell
echo "Feature.disable(:FEATURE_FLAG_NAME)" | kdk rails c
```

## Connect KhulnaSoft tracking to Product Analytics

To simplify generating test data, you can connect your KDK to your Product Analytics DevKit, which:

- Causes all normal KhulnaSoft analytics events to be sent to your DevKit as you navigate around your local copy of KhulnaSoft.
- Automatically fills Product Analytics data while you go about your work.

To connect KDK to your Product Analytics DevKit:

1. Follow the [instructions](https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/local_setup_and_debugging.html#setup-local-event-collector)
   to set up Snowplow Micro on your machine. By default, Snowplow Micro uses the same port as the Snowplow instance running within the DevKit. Therefore, you must
   follow the port change step in the instructions.
1. Enable the `additional_snowplow_tracking` ops feature flag:

   ```shell
   echo "Feature.enable(:additional_snowplow_tracking)" | kdk rails c
   ```

1. If a project hasn't already been onboarded, follow the [instructions](#onboarding-projects-to-product-analytics) to onboard a project with your Product Analytics
   self-managed provider (DevKit).
1. On the left sidebar, at the top, select **Search KhulnaSoft** (**{search}**) to find the onboarded project.
1. On the left sidebar, select **Settings > Analytics**.
1. Expand the **Data sources** section.
1. Copy the values of **SDK host** and **SDK application ID**.
1. Using [`env.runit`](../runit.md#using-environment-variables) or your terminal runtime configuration (`.bashrc`, `.zshrc` etc), add the following (replacing the values):

   ```shell
   export KHULNASOFT_ANALYTICS_URL="<SDK_HOST>"
   export KHULNASOFT_ANALYTICS_ID="<SDK_APPLICATION_ID>"
   ```

1. Restart KDK:

   ```shell
   kdk restart
   ```

1. Navigate around your KDK.
1. Go back to your KDK tracking project, which should now have data.
