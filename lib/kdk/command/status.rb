# frozen_string_literal: true

module KDK
  module Command
    # Display status of all enabled services or specified ones only
    class Status < BaseCommand
      def run(args = [])
        sh = Runit.sv_shellout('status', args)
        sh&.readlines do |line|
          out.puts prettify_line(line)
        end
        print_ready_message if args.empty?
        true
      end

      private

      def services_dir
        config.kdk_root.join('services')
      end

      def prettify_line(line)
        yellow_name = out.wrap_in_color('\1', KDK::Output::COLOR_CODE_YELLOW)

        line
          .gsub(%r{#{services_dir}/(\S+):}, "#{yellow_name}:")
          .gsub('log: ', '')
          .gsub(' run:', '')
      end
    end
  end
end
