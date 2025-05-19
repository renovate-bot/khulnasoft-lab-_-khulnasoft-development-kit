---
title: Apple M1/M2 machines
---

## `Bad CPU type in executable Target`

If you run into an error like `Bad CPU type in executable Target` on an M1 mac (`arm64`) while following this how-to guide, this typically means you're attempting to execute a binary that is incompatible with the current running environment (e.g. running an `x86_64` binary on an `arm64` system or vice-versa). On macOS, you can install [Rosetta](https://en.wikipedia.org/wiki/Rosetta_(software)) which allows running `x86_64` binaries on an `arm64` system and can be installed by running:

```shell
softwareupdate --install-rosetta
```

Be aware that once Rosetta is installed, all `x86_64` binaries will be executed silently without any warning which can potentially lead to sub-optimal performance if you're not careful.
