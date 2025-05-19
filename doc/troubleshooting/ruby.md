---
title: Troubleshooting Ruby
---

The following are possible solutions to problems you might encounter with Ruby and KDK.

## KDK command not found error

If you receive an error that the `kdk` command can't be found, it's often because of either:

- An environment issue. The Ruby environment that KDK was installed with is no longer available. For most people, this is because `mise` is no longer
  properly configured. To check if your Ruby is managed by `mise`, run:

  ```shell
  which ruby
  ```

  For most people, this command returns `/Users/<name>/.local/share/mise/shims/ruby`. If this command returns something else and you haven't set up your own
  Ruby environment, follow the [Install `mise`](https://mise.jdx.dev/installing-mise.html) instructions to reconfigure `mise`.

- A missing gem issue. The Ruby environment is correctly configured but the `khulnasoft-development-kit` gem is no longer installed. To restore the
  `khulnasoft-development-kit` gem that provides the `kdk` command, run:

   ```shell
   gem install khulnasoft-development-kit
   ```

## Rebuilding gems with native extensions

There may be times when local libraries that are used to build some gems'
native extensions are updated (for example, `libicu`), thus resulting in errors like:

```shell
rails-background-jobs.1 | /home/user/.rvm/gems/ruby-2.3.0/gems/activesupport-4.2.5.2/lib/active_support/dependencies.rb:274:in 'require': libicudata.so
cannot open shared object file: No such file or directory - /home/user/.rvm/gems/ruby-2.3.0/gems/charlock_holmes-0.7.3/lib/charlock_holmes/charlock_holmes.so (LoadError)
```

```shell
cd /home/user/khulnasoft-development-kit/khulnasoft && bundle exec rake gettext:compile > /home/user/khulnasoft-development-kit/khulnasoft/log/gettext.log 2>&1
make: *** [.gettext] Error 1
```

```shell
rake aborted!
LoadError: dlopen(/home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.5.0/gems/charlock_holmes-0.7.6/lib/charlock_holmes/charlock_holmes.bundle, 9): Library not loaded: /usr/local/opt/icu4c/lib/libicudata.63.1.dylib
  Referenced from: /home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.5.0/gems/charlock_holmes-0.7.6/lib/charlock_holmes/charlock_holmes.bundle
  Reason: image not found - /home/user/.rbenv/versions/2.6.3/lib/ruby/gems/2.5.0/gems/charlock_holmes-0.7.6/lib/charlock_holmes/charlock_holmes.bundle
```

In that case, find the offending gem and use `pristine` to rebuild its native
extensions:

```shell
bundle pristine charlock_holmes
```

Or for example `re2` on MacOS:

```shell
/Users/user/khulnasoft-development-kit/khulnasoft/lib/gitlab/untrusted_regexp.rb:25:  [BUG] Segmentation fault at 0x0000000000000000
ruby 2.6.6p146 (2020-03-31 revision 67876) [x86_64-darwin19]
```

In which case you would run:

```shell
bundle pristine re2
```

## An error occurred while installing thrift

The installation of the `thrift v0.16.0` gem during `bundle install` can fail with the following error because `clang <= 13` [does not properly handle `__has_declspec()`](https://github.com/ruby/ruby/commit/0958e19ffb047781fe1506760c7cbd8d7fe74e57):

```plaintext
[SNIPPED]

current directory: /path/to/.asdf/installs/ruby/3.1.4/lib/ruby/gems/3.1.0/gems/thrift-0.16.0/ext
/path/to/.asdf/installs/ruby/3.1.4/bin/ruby -I /path/to/.asdf/installs/ruby/3.1.4/lib/ruby/3.1.0 extconf.rb
checking for strlcpy() in string.h... *** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of necessary
libraries and/or headers.  Check the mkmf.log file for more details.  You may
need configuration options.

[SNIPPED]

To see why this extension failed to compile, please check the mkmf.log which can be found here:

 /path/to/.asdf/installs/ruby/3.1.4/lib/ruby/gems/3.1.0/extensions/x86_64-darwin-19/3.1.0/thrift-0.16.0/mkmf.log

[SNIPPED]

An error occurred while installing thrift (0.16.0), and Bundler cannot continue.

In Gemfile:
  gitlab-labkit was resolved to 0.32.0, which depends on
    jaeger-client was resolved to 1.1.0, which depends on
      thrift
```

Contents of `mkmf.log`:

```plaintext
[SNIPPED]

/path/to/.asdf/installs/ruby/3.1.4/include/ruby-3.1.0/ruby/assert.h:132:1: error: '__declspec' attributes are not enabled; use '-fdeclspec' or '-fms-extensions' to enable support for __declspec attributes
RBIMPL_ATTR_NORETURN()
^
/path/to/.asdf/installs/ruby/3.1.4/include/ruby-3.1.0/ruby/internal/attr/noreturn.h:29:33: note: expanded from macro 'RBIMPL_ATTR_NORETURN'
# define RBIMPL_ATTR_NORETURN() __declspec(noreturn)

[SNIPPED]

/path/to/.asdf/installs/ruby/3.1.4/include/ruby-3.1.0/ruby/internal/core/rbasic.h:63:14: error: expected parameter declarator
RUBY_ALIGNAS(SIZEOF_VALUE)
             ^
/path/to/.asdf/installs/ruby/3.1.4/include/ruby-3.1.0/ruby/internal/value.h:106:23: note: expanded from macro 'SIZEOF_VALUE'
# define SIZEOF_VALUE SIZEOF_LONG

[SNIPPED]
```

To work around this issue, either:

- Set the `-fdeclspec` flag and run `gem install` manually:

  ```shell
  gem install thrift -v 0.16.0 -- --with-cppflags='-fdeclspec'
  ```

- Upgrade to the latest version of Xcode or manually upgrade to `clang >= 14`. For example:

  ```shell
  brew install llvm@14
  echo 'export PATH="/usr/local/opt/llvm@14/bin:$PATH"' >> ~/.zshrc
  gem install thrift -v 0.16.0
  ```

## An error occurred while installing `gpgme` on macOS

Check if you have `gawk` installed >= 5.0.0 and uninstall it.

Re-run the `kdk install` again and follow any on-screen instructions related to installing `gpgme`.

## `gem install gpgme` `2.0.x` fails to compile native extension on macOS Mojave

If building `gpgme` gem fails with an `Undefined symbols for architecture x86_64` error on macOS Mojave, build `gpgme` using system libraries instead.

1. Ensure necessary dependencies are installed:

   ```shell
   brew install gpgme
   ```

1. (optional) Try building the `gpgme` gem manually to ensure it compiles. If it fails, debug the failure with the error messages. To compile the `gpgme` gem manually run:

   ```shell
   gem install gpgme -- --use-system-libraries
   ```

1. Configure Bundler to use system libraries for the `gpgme` gem:

   ```shell
   bundle config build.gpgme --use-system-libraries
   ```

You can now run `kdk install` or `bundle` again.

## LoadError due to readline

On macOS, KhulnaSoft may fail to start and fail with an error message about
`libreadline`:

```plaintext
LoadError:
    dlopen(/Users/kdk/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle, 9): Library not loaded: /usr/local/opt/readline/lib/libreadline.7.dylib
        Referenced from: /Users/kdk/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle
        Reason: image not found - /Users/kdk/.rbenv/versions/2.6.3/lib/ruby/2.5.0/x86_64-darwin15/readline.bundle
```

This happens because the Ruby interpreter was linked with a version of
the `readline` library that may have been updated on your system. To fix
the error, reinstall the Ruby interpreter. For example, for environments
managed with:

- [rbenv](https://github.com/rbenv/rbenv), run `rbenv install 2.7.2`.
- [RVM](https://rvm.io), run `rvm reinstall ruby-2.7.2`.

## 'LoadError: dlopen' when starting Ruby apps

This can happen when you try to load a Ruby gem with native extensions that
were linked against a system library that is no longer there. A typical culprit
is Homebrew on macOS, which encourages frequent updates (`brew update && brew
upgrade`) which may break binary compatibility.

```shell
bundle exec rake db:create dev:setup
rake aborted!
LoadError: dlopen(/Users/kdk/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle, 9): Library not loaded: /usr/local/opt/icu4c/lib/libicui18n.52.1.dylib
  Referenced from: /Users/kdk/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle
  Reason: image not found - /Users/kdk/.rbenv/versions/2.1.2/lib/ruby/gems/2.1.0/extensions/x86_64-darwin-13/2.1.0-static/charlock_holmes-0.6.9.4/charlock_holmes/charlock_holmes.bundle
/Users/kdk/khulnasoft-development-kit/khulnasoft/config/application.rb:6:in `<top (required)>'
/Users/kdk/khulnasoft-development-kit/khulnasoft/Rakefile:5:in `require'
/Users/kdk/khulnasoft-development-kit/khulnasoft/Rakefile:5:in `<top (required)>'
(See full trace by running task with --trace)
```

In the above example, you see that the `charlock_holmes` gem fails to load `libicui18n.52.1.dylib`. You can try fixing
this by [re-installing `charlock_holmes`](#rebuilding-gems-with-native-extensions).

## 'bundle install' fails due to permission problems

This can happen if you are using a system-wide Ruby installation. You can
override the Ruby gem install path with `BUNDLE_PATH`:

```shell
# Install gems in (current directory)/vendor/bundle
make BUNDLE_PATH=$(pwd)/vendor/bundle
```

## Bootsnap-related problems

If your local instance does not start up and you see `bootsnap` errors like this:

```plaintext
2020-07-09_07:29:27.20103 rails-web             : .rvm/gems/ruby-2.6.6/gems/bootsnap-1.4.6/lib/bootsnap/load_path_cache/core_ext/active_support.rb:61:in `block in load_missing_constant': uninitialized constant EE::OperationsHelper (NameError)
2020-07-09_07:29:27.20104 rails-web             : .rvm/gems/ruby-2.6.6/gems/bootsnap-1.4.6/lib/bootsnap/load_path_cache/core_ext/active_support.rb:17:in `allow_bootsnap_retry'
```

You should remove the `bootsnap` cache:

```shell
kdk stop
rm -rf gitlab/tmp/cache/bootsnap-*
kdk start
```

## Truncate Rails logs

The logs in `gitlab/log` keep growing forever as you use the KDK.

You can truncate them either manually with the provided Rake task:

```shell
rake gitlab:truncate_logs
```

Or add a [KDK hook](../configuration.md#hooks) to your `kdk.yml` with the following to truncate them
before every `kdk update`:

```yaml
kdk:
  update_hooks:
    before:
      - KDK_CLEANUP_CONFIRM=true KDK_CLEANUP_SOFTWARE=false kdk cleanup
```

## Disabled System Integrity Protection (SIP) breaks Ruby builds on macOS

If SIP is disabled, the build fails when installing the `rbs-2.7.0` gem.

```plaintext
....
rbs 2.7.0
Building native extensions. This could take a while...
/private/var/folders/rd/h6s2crs17xv0btgdvxc020sr0000gr/T/ruby-build.20230823184744.71172.TjwoSj/ruby-3.1.4/lib/rubygems/ext/builder.rb:95:in `run': ERROR: Failed to build gem native extension. (Gem::Ext::BuildError)
```

The solution is to enable SIP using the
[official instructions](https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection).

## `bundle install` returns `LoadError`

When you run `bundle install`, you might encounter the following error:

```shell
/Users/<username>/.asdf/installs/ruby/3.1.4/bin/bundle:25:in `load': cannot load such file -- /Users/<username>/.asdf/installs/ruby/3.1.4/lib/ruby/gems/3.1.0/gems/bundler-2.4.20/exe/bundle (LoadError) from /Users/<username>/.asdf/installs/ruby/3.1.4/bin/bundle:25:in `<main>'
```

To resolve this issue, run the following command to update the bundler:

```shell
gem install bundler
```

## Failed to build gem native extension error

When you run `bundle install`, you might encounter the following error:

```shell
-> % bundle install
Fetching gem metadata from https://rubygems.org/.......
Installing ruby-debug-ide 0.7.3 with native extensions
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

[SNIPPED]

No source for ruby-3.2.3-p157 (revision 52bb2ac0a6971d0391efa2275f7a66bff319087c) provided with
debase-ruby_core_source gem. Falling back to ruby-3.2.0-p0.

[SNIPPED]

debase_internals.c:770:3: error: incompatible function pointer types passing 'void (VALUE, VALUE)' (aka 'void (unsigned long, unsigned long)') to parameter of type 'VALUE (*)(VALUE, VALUE)' (aka 'unsigned long
(*)(unsigned long, unsigned long)') [-Wincompatible-function-pointer-types]
  rb_define_module_function(mDebase, "set_trace_flag_to_iseq", Debase_set_trace_flag_to_iseq, 1);
                                                          
[SNIPPED]

1 warning and 2 errors generated.
make: *** [debase_internals.o] Error 1
```

To work around this issue, run this command:

```shell
gem install debase -v 0.2.5.beta2 -- --with-cflags=-Wno-incompatible-function-pointer-types
```

## Cannot compile C++ native extensions

If you have upgraded to Xcode 16 or above and run into errors compiling
native extensions, you might be running into a [known issue with Xcode Command Line Tools](https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/2222).
Look for a compiler error loading a C++ standard library:

```plaintext
fatal error: 'cstdbool' file not found
```

```plaintext
fatal error: 'vector' file not found
```

If you are see such errors, check whether `/Library/Developer/CommandLineTools/usr/include/c++`
exists:

```shell
ls /Library/Developer/CommandLineTools/usr/include/c++
```

If it exists, you can remove it:

```shell
sudo rm -rf /Library/Developer/CommandLineTools/usr/include/c++
```

Alternatively, you can wipe the `CommandLineTools` directory and reinstall Xcode Command Line Tools:

```shell
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

You can also download the Xcode Command Line Tools from the [Apple Developer site](https://developer.apple.com).
Note that this path issue does not exist for a full Xcode installation.
