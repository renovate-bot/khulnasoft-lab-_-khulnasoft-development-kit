# frozen_string_literal: true

module KDK
  module Diagnostic
    class Gitaly < Base
      TITLE = 'Gitaly'
      MAX_GITALY_INTERNAL_SOCKET_PATH_LENGTH = 100

      def success?
        dir_length_ok?
      end

      def detail
        return if success?

        output = []
        output << dir_length_too_long_message unless dir_length_ok?

        output.join("\n#{diagnostic_detail_break}\n")
      end

      private

      def dir_length_ok?
        internal_socket_path_length <= MAX_GITALY_INTERNAL_SOCKET_PATH_LENGTH
      end

      def dir_length_too_long_message
        <<~DIR_LENGTH_TOO_LONG_MESSAGE
          Gitaly will attempt to create Unix sockets in:

            #{internal_socket_path}

          Unix socket creation issues have been observed when the character length of the
          directory above exceeds #{MAX_GITALY_INTERNAL_SOCKET_PATH_LENGTH} characters,
          and yours is #{internal_socket_path_length}.

          If you're experiencing issues, please try and reduce the directory depth to be
          under #{MAX_GITALY_INTERNAL_SOCKET_PATH_LENGTH} characters. This can be done by
          either moving the KDK directory, or by configuring the Gitaly runtime directory
          path in your `kdk.yml`.
        DIR_LENGTH_TOO_LONG_MESSAGE
      end

      def runtime_dir
        @runtime_dir ||= config.gitaly.runtime_dir
      end

      def internal_socket_path
        File.join(runtime_dir, 'gitaly-XXXXX', 'sock.d', 'XXXXXXX')
      end

      def internal_socket_path_length
        @internal_socket_path_length ||= internal_socket_path.length
      end
    end
  end
end
