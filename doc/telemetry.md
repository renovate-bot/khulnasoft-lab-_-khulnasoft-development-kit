---
title: KDK telemetry
---

> [!note]
> This page is a technical document, not a legal one.

You can opt in to KDK collecting telemetry data about your installation,
how KDK performs, and how stable it is. We use this data to make
informed, data-driven decisions about how to improve KDK.

Telemetry is pseudonymized using a random telemetry ID that is uniquely
generated per KDK installation.

As of March 28th, KhulnaSoft team members are automatically enrolled in telemetry
[as per this issue](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/2529).

Most of the telemetry-related code can be found in `lib/kdk/telemetry.rb`.

## What KDK collects

In broad terms, KDK collects the following information:

- Device metadata (e.g., processor architecture and core count)
- Installed software (e.g., operating system, `mise`/`asdf`)
- Command usage (`kdk` commands you ran, including duration and stability)
- Configured KDK services
- Exception backtraces and KDK-related logs
- Whether or not you are a KhulnaSoft team member

## How we use telemetry to improve KDK

In the past, we have already used telemetry to validate that we actually
[sped up KDK updates through parallelization](https://codingpa.ws/post/faster-updates-with-fancy-spinners).

In January of 2025, we created the first iteration of the
[KDK stats dashboard](https://kdk-stats-826305.khulnasoft.io/), which we
frequently refer to when making changes to KDK.

## How to access telemetry data

Team members who need access to telemetry data to work on KDK can submit
an [access request](https://khulnasoft.com/khulnasoft-com/team-member-epics/access-requests)
for `ClickHouse Cloud`.

After you have access, open the instance `product-analytics-prd` in
ClickHouse and use the `[EP] ClickHouse Cloud Login` password from the
`Developer Tooling` 1Password vault.
