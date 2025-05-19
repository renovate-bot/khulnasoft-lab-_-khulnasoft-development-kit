# frozen_string_literal: true

module KDK
  module ConfigType
    class Port < Integer
      def initialize(parent:, builder:, service_name:)
        @service_name = service_name

        super(parent: parent, builder: builder)
      end

      def parse(value)
        return super if parent.respond_to?(:enabled?) && !parent.enabled?

        super.tap do |validated_value|
          config.port_manager.claim(validated_value, service_name)
        end
      end

      def default_value
        super || config.port_manager.default_port_for_service(service_name)
      end

      private

      attr_reader :service_name
    end
  end
end
