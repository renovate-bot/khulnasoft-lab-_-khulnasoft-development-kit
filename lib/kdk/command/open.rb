# frozen_string_literal: true

require 'utils'

module KDK
  module Command
    # Handles `kdk reconfigure` command execution
    class Open < BaseCommand
      def run(args = [])
        return true if print_help(args)
        return wait_until_ready if args.delete('--wait-until-ready')

        open_exec
      end

      def help
        <<~HELP
          Usage: kdk open [<args>]

            -h, --help          Display help
            --wait-until-ready  Wait until the KhulnaSoft web UI is ready before opening in your default web browser
        HELP
      end

      private

      def wait_until_ready
        return open_exec if test_url.check_url_oneshot

        unless test_url.wait(verbose: false)
          KDK::Output.error('KDK is not up. Please run `kdk start` and try again.', report_error: false)
          return false
        end

        open_exec
      rescue Interrupt
        # CTRL-C was pressed
        false
      end

      def test_url
        @test_url ||= KDK::TestURL.new
      end

      def open_exec
        KDK::Output.puts("Opening #{config.__uri}")
        exec("#{open_command} '#{config.__uri}'")
      end

      def open_command
        @open_command ||= if KDK::Machine.wsl?
                            'pwsh.exe -Command Start-Process'
                          elsif Utils.find_executable('xdg-open')
                            'xdg-open'
                          # Gitpod
                          elsif Utils.find_executable('gp')
                            'gp preview --external'
                          else
                            'open'
                          end
      end
    end
  end
end
