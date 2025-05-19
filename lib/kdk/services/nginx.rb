# frozen_string_literal: true

module KDK
  module Services
    class Nginx < Base
      def name
        'nginx'
      end

      def enabled?
        config.nginx.enabled?
      end

      def command
        %(#{config.nginx.bin} -e /dev/stderr -p #{config.kdk_root.join('nginx')} -c conf/nginx.conf)
      end
    end
  end
end
