# frozen_string_literal: true

module KDK
  module Services
    class Jaeger < Base
      def name
        'jaeger'
      end

      def command
        %W[jaeger/jaeger-#{config.tracer.jaeger.version}/jaeger-all-in-one
          --memory.max-traces 512
          --admin.http.host-port "#{config.tracer.jaeger.listen_address}:14269"
          --query.http-server.host-port "#{config.tracer.jaeger.listen_address}:16686"
          --collector.http-server.host-port "#{config.tracer.jaeger.listen_address}:14268"
          --collector.grpc-server.host-port "#{config.tracer.jaeger.listen_address}:14250"
          --collector.zipkin.host-port "#{config.tracer.jaeger.listen_address}:5555"].join(' ')
      end

      def enabled?
        config.tracer.jaeger?
      end
    end
  end
end
