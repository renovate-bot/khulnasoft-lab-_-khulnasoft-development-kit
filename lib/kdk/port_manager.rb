# frozen_string_literal: true

require 'socket'
require 'timeout'

require_relative '../kdk'

module KDK
  class PortManager
    ServiceUnknownError = Class.new(StandardError)
    PortAlreadyAllocated = Class.new(StandardErrorWithMessage)
    PortInUseError = Class.new(StandardError)

    DEFAULT_PORTS_FOR_SERVICES = {
      1313 => 'docs_khulnasoft_com',
      2222 => 'sshd',
      3000 => 'kdk',
      3010 => 'khulnasoft_pages',
      3038 => 'vite',
      3333 => 'workhorse',
      3444 => 'smartcard_nginx',
      3807 => 'sidekiq_exporter',
      3808 => 'webpack',
      3907 => 'sidekiq_health_check',
      4000 => 'grafana',
      5100 => 'registry',
      5052 => 'khulnasoft_ai_gateway',
      5431 => 'postgresql_geo',
      5432 => 'postgresql',
      6000 => 'redis_cluster_dev_1',
      6001 => 'redis_cluster_dev_2',
      6002 => 'redis_cluster_dev_3',
      6003 => 'redis_cluster_test_1',
      6004 => 'redis_cluster_test_2',
      6005 => 'redis_cluster_test_3',
      6060 => 'khulnasoft-zoekt-indexer-test',
      6070 => 'khulnasoft-zoekt-webserver-test',
      6080 => 'khulnasoft-zoekt-indexer-development-1',
      6081 => 'khulnasoft-zoekt-indexer-development-2',
      6090 => 'khulnasoft-zoekt-webserver-development-1',
      6091 => 'khulnasoft-zoekt-webserver-development-2',
      6432 => 'pgbouncer_replica-1',
      6433 => 'pgbouncer_replica-2',
      6434 => 'pgbouncer_replica-2-1',
      6435 => 'pgbouncer_replica-2-2',
      8065 => 'mattermost',
      8080 => 'nginx',
      8082 => 'khulnasoft_ai_gateway_exporter',
      8100 => 'vault_proxy',
      8123 => 'clickhouse_http',
      8200 => 'vault',
      8201 => 'openbao_cluster',
      9000 => 'object_store',
      9001 => 'clickhouse_tcp',
      9002 => 'object_store_console',
      9009 => 'clickhouse_interserver',
      9090 => 'prometheus',
      9091 => 'snowplow_micro',
      9095 => 'khulnasoft_topology_service_grpc',
      9096 => 'khulnasoft_topology_service_rest',
      9122 => 'khulnasoft_shell_exporter',
      9229 => 'workhorse_exporter',
      9236 => 'gitaly_exporter',
      9393 => 'khulnasoft_http_router',
      10101 => 'praefect_exporter',
      50052 => 'duo-workflow-service'
    }.freeze

    attr_reader :claimed_ports_and_services

    def initialize(config:)
      @claimed_ports_and_services = {}
      @config = config
      @port_offset = config[:port_offset]
    end

    def claim(port, service_name)
      existing_service_name = claimed_service_for_port(port)

      if existing_service_name
        return true if existing_service_name == service_name

        raise PortAlreadyAllocated, "Port #{port} is already allocated for service '#{existing_service_name}'"
      end

      claimed_ports_and_services[port] = service_name

      true
    end

    def claimed_service_for_port(port)
      claimed_ports_and_services[port]
    end

    def default_port_for_service(name)
      services = DEFAULT_PORTS_FOR_SERVICES.to_a
      index = services.index { |service| service[1] == name }

      raise ServiceUnknownError, "Service '#{name}' is unknown, please add to KDK::PortManager::DEFAULT_PORTS_FOR_SERVICES" unless index

      if @port_offset.positive?
        @port_offset + index
      else
        services[index][0]
      end
    end

    private

    attr_writer :claimed_ports_and_services
  end
end
