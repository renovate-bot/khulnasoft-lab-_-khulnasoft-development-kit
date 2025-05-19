---
title: Troubleshooting running tests
---

There may be times when running spinach feature tests or Ruby Capybara RSpec
tests (tests that are located in the `spec/features` directory) fails.

## Normal test runs

```shell
make test
```

This runs all checks, including linters and RSpec tests. To run a specific RSpec
test, use bundler. For example:

```shell
bundle exec rspec spec/lib/kdk/diagnostic/praefect_spec.rb
```

## `pcre2.h` problems

`rspec` tests can fail with the error `'pcre2.h' file not found`. This error can occur on `arm64` macOS systems that
install `pcre2` with Homebrew.

By default, Homebrew installs packages for `arm64` under `/opt/homebrew` which causes issue for the Gitaly instance
that is built for running tests. To resolve the issue:

1. Remove the Gitaly instance that is built for running tests (it must be built again) at `<path-to-kdk>/khulnasoft/tmp/tests/gitaly`.
1. Set the `LIBPCREDIR` environment variable to `/opt/homebrew/opt/pcre2`, either:

   - Inline when running tests:

     ```shell
     LIBPCREDIR=/opt/homebrew/opt/pcre2 bundle exec rspec <path-to-test-file>
     ```

   - Permanently in your shell's configuration `export LIBPCREDIR="/opt/homebrew/opt/pcre2"`.

## ChromeDriver problems

ChromeDriver is the app on your machine that is used to run headless
browser tests.
ChromeDriver is automatically installed when running `spec/features` or `qa/` E2E tests by SeleniumManager.
SeleniumManager should install a version of ChromeDriver that is compatible with the installed version of Chrome.

If you have ChromeDriver manually installed on your system, separate to the version installed by SeleniumManager, you should uninstall it. With homebrew, run:

```shell
brew uninstall chromedriver
```

## Database problems

Another issue can be that your test environment's database schema has
diverged from what the KhulnaSoft app expects. This can happen if you tested
a branch locally that changed the database in some way, and have now
switched back to `main` without
[rolling back](https://edgeguides.rubyonrails.org/active_record_migrations.html#rolling-back)
the migrations locally first.

In that case, what you need to do is run the following command inside
the `khulnasoft` directory to drop all tables on your test database and have
them recreated from the canonical version in `db/structure.sql`. Note,
dropping and recreating your test database tables is perfectly safe!

```shell
cd khulnasoft
bundle exec rake db:test:prepare
```

## Failures when generating Karma fixtures

In some cases, running `bin/rake karma:fixtures` might fail to generate some fixtures. You can see errors in the console like these:

```plaintext
Failed examples:

rspec ./spec/javascripts/fixtures/blob.rb:25 # Projects::BlobController (JavaScript fixtures) blob/show.html
rspec ./spec/javascripts/fixtures/branches.rb:24 # Projects::BranchesController (JavaScript fixtures) branches/new_branch.html
rspec ./spec/javascripts/fixtures/commit.rb:22 # Projects::CommitController (JavaScript fixtures) commit/show.html
```

To fix this, remove `tmp/tests/` in the `khulnasoft/` directory and regenerate the fixtures:

```shell
rm -rf tmp/tests/ && bin/rake karma:fixtures
```

## TaskFailedError while setting up Gitaly

If you receive the error below, ensure that you don't have
`GIT_TEMPLATE_DIR="$(overcommit --template-dir)"`
[configured](https://github.com/sds/overcommit#automatically-install-overcommit-hooks).

```plaintext
==> Setting up Gitaly...
rake aborted!
Khulnasoft::TaskFailedError: Cloning into 'tmp/tests/gitaly'...
This repository contains hooks installed by Overcommit, but the `overcommit` gem is not installed.
Install it with `gem install overcommit`.
```

## Content Security Policy problems

Sometimes feature specs fail when run locally, due to the hot module reload (HMR) server being disallowed by the Content Security Policy. Example error:

```shell
JSConsoleError:
  Unexpected browser console output:
  webpack-internal:///AjYE 15 Refused to connect to 'ws://kdk.test:3001/_hmr/' because it violates the following Content Security Policy directive: "connect-src 'self' ws://localhost localhost".
```

Another example error:

```javascript
Uncaught runtime errors:

ERROR
Cannot read properties of null (reading 'addEventListener')
TypeError: Cannot read properties of null (reading 'addEventListener')
```

It occurs when the KhulnaSoft hostname differs from the hostname that is allowed in the Content Security Policy, for example if `hostname` has been configured in `kdk.yml`.

As a workaround:

1. Disable hot module reloading in the `kdk.yml` configuration before running feature specs:

   ```yaml
   webpack:
     live_reload: false
   ```

1. Run `kdk reconfigure`.

For more information, see [issue 1875](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/1875).

## Gitaly doesn't start

If tests don't run because `gitaly` doesn't start, run the binary manually
from the `khulnasoft` directory and look for errors:

```shell
% ./tmp/tests/gitaly/_build/bin/gitaly help
zsh: killed     ./tmp/tests/gitaly/_build/bin/gitaly help
```

In this example, if you look in the macOS crash log, look for this error:

```plaintext
Exception Type:  EXC_BAD_ACCESS (SIGKILL (Code Signature Invalid))
```

This code signing issue is a [bug present in Go 1.22.5 and earlier](https://github.com/golang/go/issues/68088).
Upgrade your default Go interpreter to 1.22.6 or later, especially
if you have Go installed with Homebrew.

See [this issue](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/2223) for more details.
