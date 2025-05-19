---
title: pgvector
---

KhulnaSoft Enterprise Edition has an optional embedding database that uses the
pgvector PostgreSQL extension. You can enable building and installing this
extension for the PostgreSQL used in your development environment.

## Installation

### Enable pgvector in the KDK

The default version of pgvector is automatically downloaded into your KDK root
under `/pgvector`.

To enable building and installing it into PostgreSQL:

1. Run `kdk config set pgvector.enabled true`.
1. Run `kdk reconfigure`.

### Switch to a different version of pgvector

The default pgvector version is defined in
[`lib/kdk/config.rb`](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/lib/kdk/config.rb).

You can change this by setting `repo` and/or `version`:

```yaml
pgvector:
  enabled: true
  repo: https://github.com/MyFork/pgvector.git
  version: v0.7.2
```

Here, `repo` is any valid repository URL that can be cloned, and `version` is
any valid ref that can be checked out.

## Troubleshooting

Building `pgvector` can fail with a `fatal error: 'stdio.h' file not found` error. For example:

```plaintext
clang: warning: no such sysroot directory: '/Library/Developer/CommandLineTools/SDKs/MacOSX13.0.sdk' [-Wmissing-sysroot]
In file included from src/ivfbuild.c:1:
In file included from /Users/myuser/.local/share/mise/installs/postgres/14.9/include/server/postgres.h:46:
/Users/myuser/.local/share/mise/installs/postgres/14.9/include/server/c.h:59:10: fatal error: 'stdio.h' file not found
#include <stdio.h>
         ^~~~~~~~~
1 error generated.
make[1]: *** [src/ivfbuild.o] Error 1
make: *** [pgvector/vector.so] Error 2
```

This error occurs because at compile-time PostgreSQL was configured to
use one XCode SDK path, but the path has been changed due to an macOS or
XCode upgrade. `kdk doctor` flags this issue.

To fix this, you should uninstall and reinstall PostgreSQL using the
following commands:

```shell
mise uninstall postgres <version>
mise install postgres <version>
```

See [the PostgreSQL troubleshooting guide](../troubleshooting/postgresql.md#fix-a-build-error-with-pgvector-extension-due-to-xcode-sdk-path-changes-on-macos) for more details.
