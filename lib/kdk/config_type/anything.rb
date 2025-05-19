# frozen_string_literal: true

module KDK
  module ConfigType
    class Anything < Base
      def parse(value)
        value
      end
    end
  end
end
