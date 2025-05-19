# frozen_string_literal: true

require 'stringio'
require 'socket'

module KDK
  module Diagnostic
    class Base
      attr_accessor :unexpected_error

      def correctable?
        self.class.method_defined?(:correct!, false)
      end

      def correct!
        raise NotImplementedError
      end

      def success?
        raise NotImplementedError
      end

      def message
        raise NotImplementedError unless title

        <<~MESSAGE

          #{status_message}#{title}
          #{diagnostic_header}
          #{message_content}
        MESSAGE
      end

      def detail
        ''
      end

      def title
        self.class::TITLE
      end

      private

      def diagnostic_header
        @diagnostic_header ||= '=' * 80
      end

      def diagnostic_detail_break
        @diagnostic_detail_break ||= '-' * 80
      end

      def message_content
        if unexpected_error
          ([unexpected_error.message] + unexpected_error.backtrace).join("\n")
        else
          detail
        end
      end

      def status_message
        '[Correctable] ' if correctable?
      end

      def config
        KDK.config
      end

      def remove_socket_file(path)
        File.unlink(path) if File.exist?(path) && File.socket?(path)
      end

      def can_create_socket?(path)
        result = true
        remove_socket_file(path)
        UNIXServer.new(path)
        result
      rescue ArgumentError => e
        raise e unless e.to_s.include?('too long unix socket path')

        false
      ensure
        remove_socket_file(path)
      end
    end
  end
end
