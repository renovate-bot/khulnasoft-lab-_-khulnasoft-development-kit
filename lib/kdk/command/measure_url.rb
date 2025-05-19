# frozen_string_literal: true

module KDK
  module Command
    class MeasureUrl < MeasureBase
      def run(urls_or_paths)
        @urls_or_paths = Array(urls_or_paths)

        super
      end

      private

      attr_reader :urls_or_paths

      def check!
        KDK::Output.abort('Please add URL(s) as an argument (e.g. http://localhost:3000/explore, /explore or https://khulnasoft.com/explore)', report_error: false) if urls.empty?
        super
      end

      def kdk_ok?
        return true unless has_local_url?

        kdk_running?
      end

      def use_git_branch_name?
        has_local_url?
      end

      def urls
        @urls ||= begin
          urls_or_paths.map do |url|
            # Transform local relative URL's
            url = "#{config.__uri}#{url}" if url_is_local?(url)

            url = url.gsub('localhost', 'host.docker.internal')
            url.gsub('127.0.0.1', 'host.docker.internal')
          end
        end.uniq
      end
      alias_method :items, :urls

      def url_is_local?(url)
        url.start_with?('/')
      end

      def has_local_url?
        @has_local_url ||= urls_or_paths.any? { |url| url_is_local?(url) }
      end

      def docker_command
        super << urls.join(' ')
      end
    end
  end
end
