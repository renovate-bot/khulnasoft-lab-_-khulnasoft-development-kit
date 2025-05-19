---
title: Shell completion
---

To enable tab completion for the `kdk` command in Bash, add the following to your `~/.bash_profile`:

```shell
source ~/path/to/your/kdk/support/completions/kdk.bash
```

For Zsh, you can enable Bash completion support in your `~/.zshrc`:

```shell
autoload bashcompinit
bashcompinit

source ~/path/to/your/kdk/support/completions/kdk.bash
```
