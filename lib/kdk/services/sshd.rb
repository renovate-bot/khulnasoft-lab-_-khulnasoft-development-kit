# frozen_string_literal: true

module KDK
  module Services
    class Sshd < Base
      def name
        'sshd'
      end

      def enabled?
        config.sshd.enabled?
      end

      def command
        if config.sshd.use_khulnasoft_sshd?
          %(#{config.khulnasoft_shell.dir}/bin/gitlab-sshd -config-dir #{config.khulnasoft_shell.dir})
        else
          %(#{config.sshd.bin} -e -D -f #{config.kdk_root.join('openssh', 'sshd_config')})
        end
      end
    end
  end
end
