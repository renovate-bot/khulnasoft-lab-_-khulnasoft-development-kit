# frozen_string_literal: true

require 'stringio'

module KDK
  class OutputBuffered
    include KDK::Output

    def initialize
      @output = StringIO.new
    end

    def stdout_handle
      output
    end

    def stderr_handle
      output
    end

    def dump
      output.string
    end

    private

    attr_reader :output
  end
end
