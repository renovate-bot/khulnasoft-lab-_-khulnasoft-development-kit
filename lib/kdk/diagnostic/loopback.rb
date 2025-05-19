# frozen_string_literal: true

module KDK
  module Diagnostic
    class Loopback < Base
      TITLE = 'Loopback interface'

      def success?
        return true unless needs_loopback?
        return true unless KDK::Machine.macos?

        loopback_configured?
      end

      def detail
        return if success?

        <<~MESSAGE
          You have configured #{config.listen_address} as listen address, so you
          need to create a loopback interface for KDK to work properly.

          You can do this by running the following command:

            sudo ifconfig lo0 alias #{config.listen_address}
        MESSAGE
      end

      private

      def needs_loopback?
        config.listen_address == '172.16.123.1'
      end

      def loopback_configured?
        sh = KDK::Shellout.new(%w[ifconfig lo0])

        sh.run.include?(config.listen_address)
      end
    end
  end
end
