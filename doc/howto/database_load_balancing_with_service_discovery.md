---
title: Database load balancing with service discovery
---

This document describes how to enable and test the [database load balancing with service discovery of replicas](https://docs.khulnasoft.com/ee/administration/postgresql/database_load_balancing.html#service-discovery) feature in KDK. To do this, you must run multiple TCP ports for Postgres as well as a DNS server to respond with those different Postgres ports.

If you only want to test load balancing features but do not want to test service discovery, see the [Database load balancing documentation](database_load_balancing.md).

## Prerequisites

You must install:

- [Consul](https://developer.hashicorp.com/consul/docs/install) to act as a DNS server that responds with the list of Postgres servers using an SRV record with the IP address and record ports.
- [PgBouncer](https://www.pgbouncer.org/install.html) to act as a load balancer and provide multiple ports proxying the same Postgres server.

## Assumptions

For these instructions, we assume that you are running all commands from the KDK root.

## Prepare your environment

1. Update your `kdk.yml`:

   ```yaml
   postgresql:
     replica:
       enabled: true
     replica_2:
       enabled: true
   load_balancing:
     discover:
       enabled: true
   pgbouncer_replicas:
     enabled: true
   ```

1. Reconfigure KDK:

   ```shell
   kdk reconfigure
   ```

1. You should now have 3 Postgres clusters:

   1. Primary: `<kdk-root>/postgresql`
   1. Replica 1: `<kdk-root>/postgresql-replica`
   1. Replica 2: `<kdk-root>/postgresql-replica-2`

1. Restart KDK:

   ```shell
   kdk restart
   ```

## Validate that rails is correctly discovering all replicas

1. Validate that Consul service discovery is correctly finding the PgBouncer processes:

   ```shell
   $ dig +short @127.0.0.1 -p 8600 replica.pgbouncer.service.consul -t SRV
   1 1 6433 localhost.
   1 1 6432 localhost.
   1 1 6435 localhost.
   1 1 6434 localhost.
   ```

1. Confirm that Rails has connected to all the replicas:

   ```shell
   PGPASSWORD=khulnasoft psql -U $(whoami) -h localhost -p 6435 -d pgbouncer -c 'show clients'
   ```

If it is working as expected, you should see multiple clients in the output.

## Troubleshooting

### Debugging the `ServiceDiscovery`

The following Ruby snippets give visibility into what's happening in
service discovery, and are useful for debugging:

```ruby
configuration = ::Khulnasoft::Database::LoadBalancing::Configuration.for_model(::ActiveRecord::Base)

load_balancer = ::Khulnasoft::Database::LoadBalancing::LoadBalancer.new(configuration)

sv = ::Khulnasoft::Database::LoadBalancing::ServiceDiscovery.new(load_balancer, **configuration.service_discovery)

sv.resolver.search("replica.pgbouncer.service.consul", Net::DNS::SRV) # Inspect the DNS result

sv.addresses_from_dns # Inspect the list of hosts discovered
```

```ruby
resolver ||= Net::DNS::Resolver.new(nameservers: "127.0.0.1", port: 8600, use_tcp: true)

resolver.search("replica.pgbouncer.service.consul", Net::DNS::SRV)

resolver.search("replica.pgbouncer.service.consul", Net::DNS::SRV).answer.map { |r| { host: r.host, port: r.port } }
```

### Show the list of replica connections

```ruby
ActiveRecord::Base.connection.load_balancer.host_list.hosts.map(&:host)
ActiveRecord::Base.connection.load_balancer.host_list.hosts.map(&:port)
```

## Simulating replication delay

To simulate replication delay, see the [database load balancing documentation](database_load_balancing.md#simulating-replication-delay). You can simulate replication delay on specific replicas only, to test the behavior of load balancing to choose an up-to-date replica.
