# frozen_string_literal: true

require 'pathname'

module KDK
  module Services
    class KhulnasoftTopologyService < Base
      def name
        'khulnasoft-topology-service'
      end

      def command
        "support/exec-cd khulnasoft-topology-service go run . serve"
      end

      def ready_message
        'The TopologyService is up and running.'
      end

      def enabled?
        config.khulnasoft_topology_service.enabled?
      end
    end
  end
end
