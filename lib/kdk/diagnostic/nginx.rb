# frozen_string_literal: true

module KDK
  module Diagnostic
    class Nginx < Base
      TITLE = 'KDK NGINX Configuration'

      def success?
        return true unless config.nginx.enabled?

        test_cmd.execute(display_output: false, display_error: false)
        test_cmd.success?
      end

      def detail
        return if success?

        <<~MESSAGE
          nginx/conf/nginx.conf is not valid!
          #{test_cmd.read_stdout}
          #{test_cmd.read_stderr}
        MESSAGE
      end

      private

      def nginx_bin
        config.find_executable!('nginx')
      end

      def nginx_dir
        File.join(config.kdk_root, 'nginx')
      end

      def relative_nginx_config
        File.join('conf', 'nginx.conf')
      end

      def test_cmd
        @test_cmd ||= Shellout.new(nginx_bin, '-p', nginx_dir, '-c', relative_nginx_config, '-q', '-t')
      end
    end
  end
end
