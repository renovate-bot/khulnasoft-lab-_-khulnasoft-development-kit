# frozen_string_literal: true

module KDK
  module Command
    # Start all enabled services or specified ones only
    class Stop < BaseCommand
      def run(args = [])
        KDK::Hooks.with_hooks(config.kdk.stop_hooks, 'kdk stop') do
          if args.empty?
            # Runit.stop will stop all services and stop Runit (runsvdir) itself.
            # This is only safe if all services are shut down; this is why we have
            # an integrated method for this.
            Runit.stop
          else
            # Stop the requested services, but leave Runit itself running.
            Runit.sv('force-stop', args)
          end
        end
      end
    end
  end
end
