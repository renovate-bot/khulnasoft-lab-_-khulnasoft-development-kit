# frozen_string_literal: true

module KDK
  module Command
    # Start all enabled services or specified ones only
    class Start < BaseCommand
      def help
        <<~HELP
          Usage: kdk start [<args>]

            -h, --help         Display help
            --quiet            Don't display any output
            --show-progress    Indicate when KDK is ready to use
              or
            --open-when-ready  Open the KhulnaSoft web UI running in your local KDK installation, using your default web browser
        HELP
      end

      def run(args = [])
        return true if print_help(args)

        quiet = !args.delete('--quiet').nil?
        show_progress = !args.delete('--show-progress').nil?
        open_when_ready = !args.delete('--open-when-ready').nil?

        result = KDK::Hooks.with_hooks(config.kdk.start_hooks, 'kdk start') do
          Runit.start(args, quiet: quiet)
        end

        if args.empty?
          # Only print if run like `kdk start`, not like `kdk start rails-web`
          print_ready_message
        end

        if show_progress
          KDK::Output.puts
          test_url
        elsif open_when_ready
          KDK::Output.puts
          open_in_web_browser
        end

        result
      end

      private

      def test_url
        KDK::TestURL.new.wait
      end

      def open_in_web_browser
        KDK::Command::Open.new.run(%w[--wait-until-ready])
      end
    end
  end
end
