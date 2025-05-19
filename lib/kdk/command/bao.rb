# frozen_string_literal: true

module KDK
  module Command
    # Configures openbao client
    class Bao < BaseCommand
      def run(args = [])
        unless KDK.config.openbao.enabled?
          KDK::Output.warn('OpenBao is not enabled. See doc/howto/openbao.md for getting started with OpenBao.')
          return false
        end

        case args.pop
        when 'configure'
          KDK::OpenBao.new.configure
        else
          KDK::Output.warn('Usage: kdk bao configure')
          false
        end
      end
    end
  end
end
