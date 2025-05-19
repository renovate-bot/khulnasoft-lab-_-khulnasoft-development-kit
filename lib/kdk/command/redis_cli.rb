# frozen_string_literal: true

module KDK
  module Command
    # Executes bundled redis-cli with any provided extra arguments
    class RedisCli < BaseCommand
      def run(args = [])
        exec('redis-cli', '-s', config.redis.__socket_file.to_s, *args, chdir: KDK.root)
      end
    end
  end
end
