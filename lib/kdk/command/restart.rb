# frozen_string_literal: true

module KDK
  module Command
    # Stop and restart all enabled services or specified ones only
    class Restart < BaseCommand
      def help
        KDK::Command::Start.new.help.gsub('kdk start', 'kdk restart')
      end

      def run(args = [])
        return true if print_help(args)

        # Stop does not support --<arg> being passed in, so we need to strip
        # them here.
        KDK::Command::Stop.new.run(args.reject { |x| x.start_with?('--') })

        # Give services a little longer to shutdown.
        sleep(3)

        KDK::Command::Start.new.run(args)
      end
    end
  end
end
