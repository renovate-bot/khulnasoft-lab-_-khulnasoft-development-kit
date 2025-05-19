---
title: NFS
---

If you want to experiment with how KhulnaSoft behaves over NFS you can use a setup
where your development machine is simultaneously an NFS client and server, with
KhulnaSoft reading/writing data as the client.

## Ubuntu / Debian

```shell
sudo apt-get install -y nfs-kernel-server

# All our NFS exports (data on the 'server') is under /exports/khulnasoft-data
sudo mkdir -p /exports/khulnasoft-data/{repositories,khulnasoft-satellites,.ssh}
# We assume your developer user is git:git
sudo chown git:git /exports/khulnasoft-data/{repositories,khulnasoft-satellites,.ssh}

sudo mkdir /etc/exports.d
echo '/exports/khulnasoft-data 127.0.0.1(rw,sync,no_subtree_check)' | sudo tee /etc/exports.d/khulnasoft-data.exports
sudo service portmap restart
sudo service nfs-kernel-server restart
sudo exportfs -v 127.0.0.1:/exports/khulnasoft-data # should show /exports/khulnasoft-data

# We assume the current directory is the root of your khulnasoft-development-kit
sudo mkdir -p .ssh repositories khulnasoft-satellites
sudo mount 127.0.0.1:/exports/khulnasoft-data/.ssh .ssh
sudo mount 127.0.0.1:/exports/khulnasoft-data/repositories repositories
sudo mount 127.0.0.1:/exports/khulnasoft-data/khulnasoft-satellites khulnasoft-satellites
# TODO: put the above mounts in /etc/fstab ?
```
