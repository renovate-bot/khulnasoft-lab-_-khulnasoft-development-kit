# frozen_string_literal: true

require 'net/http'

module KDK
  class HTTPHelper
    attr_reader :last_response_reason

    HTTP_SUCCESS_CODES = %w[200 301 302].freeze

    def initialize(uri, read_timeout: 5, open_timeout: 5, cache_response: true)
      raise 'uri needs to be an instance of URI' unless uri.is_a?(URI)

      @uri = uri
      @read_timeout = read_timeout
      @open_timeout = open_timeout
      @cache_response = cache_response
    end

    def up?(codes_to_consider_up: HTTP_SUCCESS_CODES)
      get_up?(codes_to_consider_up: codes_to_consider_up)
    end

    def head_up?(codes_to_consider_up: HTTP_SUCCESS_CODES)
      response_to_process = cache_response ? cached_http_head_response : http_head_response
      return false unless response_to_process

      codes_to_consider_up.include?(response_to_process.code)
    end

    def get_up?(codes_to_consider_up: HTTP_SUCCESS_CODES)
      response_to_process = cache_response ? cached_http_get_response : http_get_response
      return false unless response_to_process

      codes_to_consider_up.include?(response_to_process.code)
    end

    private

    attr_reader :uri, :read_timeout, :open_timeout, :cache_response

    def cached_http_get_response
      @cached_http_get_response ||= http_get_response
    end

    def cached_http_head_response
      @cached_http_head_response ||= http_head_response
    end

    def http_get_response
      response { |http| http.get(path) }
    end

    def http_head_response
      response { |http| http.head(path) }
    end

    def path
      @path ||= uri.path.empty? ? '/' : uri.path
    end

    def response(&blk)
      resp = http_client.start(&blk)

      @last_response_reason = "#{resp.code} #{resp.message}"
      resp
    rescue Errno::ECONNREFUSED
      @last_response_reason = 'Connection refused'
      false
    rescue Net::ReadTimeout
      @last_response_reason = 'Request timed out'
      false
    end

    def http_client
      Net::HTTP.new(uri.host, uri.port).tap do |client|
        client.read_timeout = read_timeout
        client.open_timeout = open_timeout
        client.use_ssl = uri.scheme == 'https'
      end
    end
  end
end
