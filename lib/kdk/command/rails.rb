# frozen_string_literal: true

module KDK
  module Command
    # Handles `kdk rails <command> [<args>]` command execution
    class Rails < BaseCommand
      def run(args = [])
        KDK::Output.abort('Usage: kdk rails <command> [<args>]', report_error: false) if args.empty?

        execute_command!(args)
      end

      private

      def execute_command!(args)
        exec(
          KDK.config.env,
          *generate_command(args),
          chdir: KDK.root.join('khulnasoft')
        )
      end

      def generate_command(args)
        %w[../support/bundle-exec rails] + args
      end
    end
  end
end
