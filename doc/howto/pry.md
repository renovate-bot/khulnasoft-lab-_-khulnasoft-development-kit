---
title: Debugging with Pry
---

[Pry](https://pry.github.io/) allows you to set breakpoints in Ruby code
for interactive debugging. Just drop the magic line into your code:

```ruby
require 'pry-byebug'; binding.pry
```

`pry-byebug` is a [plugin](https://github.com/pry/pry/wiki/Available-plugins#pry-byebug)
that adds `next`, `step`, `finish` and `continue` commands to step through
the code.

When running tests, Pry's interactive debugging prompt appears in the
terminal window where you start your test command (`rake`, `rspec` etc.).

To get a debugging prompt while browsing local
development server (<http://localhost:3000>), use `binding.pry_shell` instead.

You can then connect to this session by running `pry-shell` in your terminal. See
[Pry debugging docs](https://docs.khulnasoft.com/ee/development/pry_debugging.html)
for more usage.

## Run a web server in the foreground

An alternative to `binding.pry_shell` is to run your Rails web server Puma in
the foreground.
Start by kicking off the normal KDK processes via `kdk start`. Then open a new
terminal session and run:

```shell
kdk stop rails-web && KHULNASOFT_RAILS_RACK_TIMEOUT_ENABLE_LOGGING=false PUMA_SINGLE_MODE=true kdk rails s
```

This starts a single mode Puma server in the foreground with only one thread. Once the
`binding.pry` breakpoint has been reached, Pry prompts appear in the window
that runs `kdk rails s`.

When you have finished debugging, remove the `binding.pry` breakpoint and go
back to using Puma in the background. Terminate `kdk rails s` by pressing Ctrl-C
and run `kdk start rails-web`.

> [!note]
> It's not possible to submit commits from the web without at least two Puma server
> threads running. This means when running Puma in the foreground for debugging,
> actions such as creating a file from the web time out.
