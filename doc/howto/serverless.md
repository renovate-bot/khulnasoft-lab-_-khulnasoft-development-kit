---
title: Serverless (Knative)
---

This document instructs you to set up a working KhulnaSoft instance that can
deploy Serverless applications (that is, Knative services) to a Kubernetes cluster
via KhulnaSoft CI/CD.

## Prerequisites

Please follow all the instructions for [setting up Kubernetes](kubernetes/_index.md) before following
any steps in here.

## Minimal getting started guide

1. Since Serverless builds with Kaniko, follow workaround instructions
   in
   <https://github.com/khulnasoft-lab/khulnasoft-development-kit/issues/547#workaround>
   until this problem is solved
1. Create a new project
1. Add a cluster to the project
1. Install Tiller and Knative on the cluster.
   When installing Knative you are asked for a domain name. You later need
   to set up a DNS record for this domain name in order to reach your deployed
   serverless applications so it's necessary that you own this domain name.
   Alternatively there are some
   [workarounds to avoid buying a domain name](#workarounds-to-avoid-buying-a-domain-name) below.
1. Assuming you used a domain name that you own, you then need to set up a
   wildcard DNS record that points to the IP address of the Knative Ingress.
   Once the IP address finishes fetching (usually a few minutes after Knative
   install finishes) then go to your DNS provider and set up a wildcard A record
   pointing to this IP address. Assuming you used `example.com` as the domain
   for Knative and the IP address is `1.2.3.4` then you need to create an `A`
   record like `*.example.com -> 1.2.3.4`.
1. Now clone
   [this minimal example Ruby app](https://khulnasoft.com/khulnasoft-org/cluster-integration/knative-examples/knative-ruby-app-kubectl)
   and push to your project to deploy a Knative service

## Workarounds to avoid buying a domain name

Unfortunately we cannot use the same technique we use with Auto DevOps to avoid
buying a domain name (ie. using `nip.io`) since the IP address loads after
setting the hostname and we have no way to update the hostname.

Some other options for avoiding buying a domain name include:

- If you are just testing locally all you need to do is trick the DNS resolver
  on your computer to think that you own `example.com` and think that it is
  pointing to the IP address of Knative. You can do this in multiple ways but
  the simplest way is to edit the `/etc/hosts` file on your machine to
  basically add line like `<ip-address> <blah>.example.com` where
  `<ip-address>` is the IP of Knative shown in the UI and `<blah>.example.com`
  is the domain of your function in the serverless tab or CI output.
- There is another way to trick your computer to call to a specific domain for
  a Knative function using curl which is that you can make a request to the
  function like `curl -H 'Host: <blah>.example.com' "http://<ip-address>"` and
  this should also end up executing the function for you. This ensures the
  request reaches the IP address of your Knative Ingress and setting the `Host`
  header ensures that the Knative Ingress knows which function to forward the
  request to.
