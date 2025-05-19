---
title: NFS
---

If you want to experiment with how KhulnaSoft behaves over NFS you can use a setup
where your development machine is simultaneously an NFS client and server, with
KhulnaSoft reading/writing data as the client.

## Ubuntu / Debian

```shell
sudo apt-get install -y nfs-kernel-server

# All our NFS exports (data on the 'server') is under /exports/gitlab-data
sudo mkdir -p /exports/gitlab-data/{repositories,gitlab-satellites,.ssh}
# We assume your developer user is git:git
sudo chown git:git /exports/gitlab-data/{repositories,gitlab-satellites,.ssh}

sudo mkdir /etc/exports.d
echo '/exports/gitlab-data 127.0.0.1(rw,sync,no_subtree_check)' | sudo tee /etc/exports.d/gitlab-data.exports
sudo service portmap restart
sudo service nfs-kernel-server restart
sudo exportfs -v 127.0.0.1:/exports/gitlab-data # should show /exports/gitlab-data

# We assume the current directory is the root of your khulnasoft-development-kit
sudo mkdir -p .ssh repositories gitlab-satellites
sudo mount 127.0.0.1:/exports/gitlab-data/.ssh .ssh
sudo mount 127.0.0.1:/exports/gitlab-data/repositories repositories
sudo mount 127.0.0.1:/exports/gitlab-data/gitlab-satellites gitlab-satellites
# TODO: put the above mounts in /etc/fstab ?
```
