---
title: Kubernetes - tips and troubleshooting
---

- [Tips](#tips)
- [Troubleshooting](#troubleshooting)

## Tips

### Useful Commands

Besides this list of tips and troubleshooting, see our list of
[useful commands](useful_commands.md).

### QA

- Consider adding `require 'pry'; binding.pry` breakpoint before
  [the last assertion about builds](https://github.com/khulnasoft-lab/khulnasoft-foss/blob/eb146e9abe08c3991b5a54237c24d15312c70ee8/qa/qa/specs/features/browser_ui/7_configure/auto_devops/create_project_with_auto_devops_spec.rb#L61)
  to save yourself from setting up a full working Auto DevOps project.

- Set the environment variable `CHROME_REUSE_PROFILE` to `true` which
  allows QA to re-use the same user profile so that slow files such
  as `main.chunk.js` can be cached in memory.

- Disable source-maps for KDK by setting the environment variable
  `NO_SOURCEMAPS` to `true`. This reduces the size of `main.chunk.js`
  from 11 MB to 4.6 MB, which helps connections with slow upload speeds.

### Helm/Tiller Communication

One can run manual Helm commands from your local machine and communicate to our remote Tiller
running on GKE. See [Local Tiller](useful_commands.md#local-tiller) to know how to achieve it.

### Configuration for Auto DevOps base domain

Please refer to the [Auto DevOps Base Domain](https://docs.khulnasoft.com/ee/topics/autodevops/#auto-devops-base-domain) to learn more about it.

## Using an external virtual machine for the development

If you decide to use an external virtual machine to run KDK on it, you might
want to still be able to use your favorite tools and IDE locally.

If you decide to follow this direction it might be a good idea to avoid
uploading your private SSH keys there, in case if you want to push to
KhulnaSoft from the virtual machine.

You can use [`unison`](https://www.cis.upenn.edu/~bcpierce/unison/index.html)
to synchronize your local and remote files. Use:

```shell
unison -batch ./kdk ssh://my-account@gcp.vm.example.com
```

You need to install `unison` locally and on the remote machine with

```shell
apt-get install unison
```

`unison` makes it easier to synchronize files bi-directionally, however it does
not happen automatically, you need to invoke the command to trigger the
synchronization.

Some people also use [Mutagen](https://github.com/havoc-io/mutagen) instead of
`unison`, you can also give it a try and choose the solution you prefer.

It is also possible to configure your environment in a way that only local ->
remote synchronization is needed. In this case you can use `lsyncd` tool, which
appears to work reasonably well when bi-directional communication is not
needed.

## Troubleshooting

### The Ingress is never assigned an IP address

If your Ingress is never assigned an IP address and you've waited for the IP address to appear on the cluster page for several minutes, it's quite possible that your GCP project has hit a limit of static IP addresses. See [how to clean up unused load balancers above](_index.md#unused-load-balancers).

### Error due to `Insufficient regional quota` for `DISKS_TOTAL_GB`

When [creating a new GKE cluster](https://docs.khulnasoft.com/ee/user/project/clusters/#creating-the-cluster), GKE creates persistent disks for you. If you are
running into the following error:

```plaintext
ResponseError: code=403, message=Insufficient regional quota to satisfy request: resource "DISKS_TOTAL_GB"
```

this would indicate you have reached your limit of persistent disks. See
[how to clean up unused persistent disks above](_index.md#unused-persistent-disks).
