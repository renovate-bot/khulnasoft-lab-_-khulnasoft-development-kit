---
title: Tool Upgrade Guides for KDK
---

This documentation provides standardized procedures for upgrading critical development tools in KDK. Following these guidelines ensures a smooth transition between tool versions while minimizing disruption to developers.

## PostgreSQL

This guide outlines the process for updating the default PostgreSQL version in KDK.

The approach described here:

- Installs the new version for all users without making it the default.
- Allows users to manually test with the new version if desired.
- Prevents automatic upgrades of existing databases.

To update the default PostgreSQL:

1. Run initial tests with a scheduled pipeline:
   1. Set the `TARGET_POSTGRES_VERSION` in [`_versions.gitlab-ci.yaml`](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/master/.gitlab/ci/_versions.gitlab-ci.yml).
      
      This enables a nightly scheduled pipeline that:
      - Replaces the current PostgreSQL version with the target version.
      - Runs `KDK_SELF_UPDATE=0 kdk update` to install the target version and execute `support/upgrade-postgresql`.
      - Starts KDK via `kdk start`.
      - Performs a basic verification test by sending a `curl` request to the sign-in endpoint.

   Tests currently run on Linux (in Docker).

1. Monitor integration builds:
   1. Monitor [`integration:postgres-upgrade` runs](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/jobs?name=postgres-upgrade).
   1. Observe build results to identify compatibility issues.
   1. Document errors and their root causes.
   1. Create tracking issues for significant problems requiring resolution.

1. Resolve issues:
   1. Address all identified issues with appropriate fixes.
   1. Test fixes in the scheduled pipeline to verify their effectiveness.
   1. Update documentation with any special handling required for the new version.

1. Roll out the changes:
   1. Update `.tool-versions` to add the new PostgreSQL version.
      You must do this for both the KhulnaSoft and KDK projects.
   1. Add a KDK announcement to inform users about the newly installed PostgreSQL version.
   
   For example, see:
   - [Add 16.8 to KDK](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/merge_requests/4667)
   - [Add 16.8 to KhulnaSoft](https://github.com/khulnasoft-lab/khulnasoft/-/merge_requests/185192)

1. Verify installation:
   1. Monitor for [installation issues reported by users](https://dashboards.quality.gitlab.net/d/feiggichlw64gf/kdk-command-failure-rates?var-time_interval=1h&orgId=1&from=now-2d&to=now&timezone=browser&var-commands=rake%20update:tool-versions).
   1. Address platform-specific installation problems, particularly macOS and Linux differences.
   1. Update installation scripts and documentation to resolve common issues.

1. Fully deploy the change:
   1. Once installation stability is confirmed, update `.tool-versions` to set the new version as default.
   1. Move the new version to the [first position in the version list](https://dashboards.quality.gitlab.net/d/feiggichlw64gf/kdk-command-failure-rates?var-time_interval=1h&orgId=1&from=now-7d&to=now&timezone=browser&var-commands=rake%20update:tool-versions&var-commands=rake%20preflight-update-checks&var-commands=rake%20gitlab-db-migrate).
   - Communicate the change to all developers through appropriate channels.
   - Provide guidance on handling any post-upgrade issues that may arise.
   
   For example, see these MRs:
     - [13.9 to 14.9](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/merge_requests/3263)
     - [14.9 to 16.8](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/merge_requests/4647)

### Best practices

- Allow sufficient time between stages for thorough testing.
- Document all encountered issues and their resolutions for future reference.
- Consider platform-specific concerns, especially for macOS and Linux differences.
- Where possible, maintain backward compatibility during the transition period.
- Provide clear developer communication at each major stage of the process.
