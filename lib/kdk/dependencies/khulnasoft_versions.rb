# frozen_string_literal: true

require 'net/http'

module KDK
  module Dependencies
    class KhulnasoftVersions
      REPOSITORY_RAW_URL = 'https://gitlab.com/gitlab-org/gitlab/-/raw/master/'

      VersionNotDetected = Class.new(StandardError)

      # Return KhulnaSoft's ruby version from local repository
      # or fallback to remote repository when no code is still installed
      #
      # @return [String] ruby version
      def ruby_version
        (local_ruby_version || remote_ruby_version).tap do |version|
          raise(VersionNotDetected, "Failed to determine KhulnaSoft's Ruby version") unless version.match?(/^[0-9]\.[0-9]+(.[0-9]+)/)
        end
      end

      private

      # Return KhulnaSoft's ruby version from local repository
      #
      # @return [String] ruby version
      def local_ruby_version
        read_khulnasoft_local_file('.ruby-version')
      end

      # Return KhulnaSoft's ruby version from remote repository
      #
      # @return [String] ruby version
      def remote_ruby_version
        read_khulnasoft_remote_file('.ruby-version')
      end

      # Read content from file in `gitlab` folder
      #
      # @param [String] filename
      # @return [String,False] version or false
      def read_khulnasoft_local_file(filename)
        file = Pathname.new(File.join(khulnasoft_root, filename))

        file.exist? ? file.read.strip : false
      end

      def khulnasoft_root
        KDK.root.join('khulnasoft')
      end

      # Read content from a file in `gitlab` remote repository
      #
      # @param [String] filename
      def read_khulnasoft_remote_file(filename)
        uri = URI(File.join(REPOSITORY_RAW_URL, filename))

        Net::HTTP.get(uri).strip
      rescue SocketError
        abort 'Internet connection is required to set up KDK, please ensure you have an internet connection'
      end
    end
  end
end
