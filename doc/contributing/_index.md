---
title: Contributing to KhulnaSoft Development Kit
---

This document describes how to contribute code to KhulnaSoft Development Kit (KDK).

## Contributing new KDK features

Contribute new features to KDK by:

- Creating a new KDK command.
- Adding a new service for KDK to manage.
- Adding a new capability to existing KDK commands, setup, or service.

### Creating a new KDK command

KDK commands manage operations that affect the entire KDK environment. KDK commands should:

- Perform actions that impact multiple services or the overall KDK setup.
- Not be specific to a single service (for example, database migrations).

Existing `kdk` commands include:

- `kdk start` and `kdk stop` to start and stop all services.
- `kdk update` to update your KDK environment.
- `kdk doctor` to verify the overall health of your KDK setup.

Don't create a KDK command to do things such as:

- Populating data for a single service.
- Performing setup tasks specific to one service.
- Running database migrations for a single service.

Instead, use a Rake task in these cases because they are more appropriate for service-specific actions.

### Creating a new KDK-managed service or Rake task

Use Rake tasks for service-specific actions.

Don't create new service-specific Makefiles (for example, `Makefile.<service name>.mk`) because we're moving individual
Ruby services. Services are stored in `lib/kdk/services`.

Each Ruby service can implement hooks for:

- Setup
- Installation
- Updates

For complex setup procedures:

1. Create a dedicated Rake task.
1. Execute it as part of the setup hook.

When you create new KDK commands or Rake tasks, follow the existing patterns in the KDK codebase.

For more information about this ongoing work, see <https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/166>.

### Running and debugging tests

This runs different tests for things that are about to be pushed.

```shell
make test
```

This runs all Ruby tests regardless of changes.

```shell
bundle exec rspec
```

For debugging tests [use Pry](../howto/pry.md).
