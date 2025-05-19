# frozen_string_literal: true

require 'stringio'

module KDK
  module Diagnostic
    class Configuration < Base
      TITLE = 'KDK Configuration'

      def success?
        config_diff.empty?
      end

      def detail
        <<~MESSAGE
          Please review the following diff(s) and/or consider running `kdk reconfigure`:

          #{config_diff}
        MESSAGE
      end

      def config_diff
        @config_diff ||= begin
          output = KDK::OutputBuffered.new
          KDK::Command::DiffConfig.new(out: output).run
          output.dump.chomp
        end
      end
    end
  end
end
