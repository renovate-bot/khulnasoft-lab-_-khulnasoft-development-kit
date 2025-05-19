---
title: Using feature flags
---

To use feature flags in the KDK, you can:

- Use the user interface.
- Use the command line.

## User interface

To view and toggle feature flags in the UI:

- Manually navigate to the `/rails/features` path in your KDK, for example <http://kdk.test:3000/rails/features>.

## Command line

Open the [Rails console](rails_console.md) and run these commands:

- To enable a feature flag for the instance:

  ```shell
  Feature.enable(:<dev_flag_name>)
  ```

- To disable a feature flag for the instance:

  ```shell
  Feature.disable(:<dev_flag_name>)
  ```

- To enable or disable a feature flag for a specific project:

  ```shell
  # To enable for a specific project:
  Feature.enable(:<dev_flag_name>, Project.find(<project id>))

  # To disable for a specific project:
  Feature.disable(:<dev_flag_name>, Project.find(<project id>))
  ```
