# frozen_string_literal: true

require 'pathname'

module KDK
  module ConfigType
    class Path < Base
      def dump!(*)
        value.to_s
      end

      def parse(value)
        Pathname.new(value)
      end

      private

      def string_like?
        %w[String Pathname].include?(value.class.to_s)
      end
    end
  end
end
