# frozen_string_literal: true

module KDK
  module ConfigType
    class Integer < Base
      def parse(value)
        ival = value.to_i

        raise ::TypeError unless value.to_s == ival.to_s

        ival
      end
    end
  end
end
