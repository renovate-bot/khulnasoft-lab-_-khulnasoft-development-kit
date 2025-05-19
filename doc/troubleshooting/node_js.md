---
title: Troubleshooting Node.js
---

The following are possible solutions to problems you might encounter with Node.js and KDK.

## Error installing node-gyp

node-gyp may fail to build on macOS Catalina installations. Follow [the node-gyp troubleshooting guide](https://github.com/nodejs/node-gyp/blob/master/macOS_Catalina.md).

## 'yarn install' fails due node incompatibility issues

If you're running a version of node between 13.0 and 13.7, you might see the following error message:

```plaintext
error extract-files@8.1.0: The engine "node" is incompatible with this module. Expected version "10 - 12 || >= 13.7". Got "13.2.0"
error Found incompatible module.
```

If you're using `nvm`, you can confirm the version of node that you're using:

```shell
nvm current node -v
```

You can adjust node to an acceptable version with the following command:

```shell
nvm install <version>
```

## yarn: error: no such option: --pure-lockfile

The full error you might be getting is:

```plaintext
Makefile:134: recipe for target '.gitlab-yarn' failed
make: *** [.gitlab-yarn] Error 2
```

This is likely to happen if you installed `yarn` using `apt install cmdtest`.

To fix this, install yarn using npm instead:

```shell
npm install --global yarn
```
