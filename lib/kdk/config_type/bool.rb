# frozen_string_literal: true

module KDK
  module ConfigType
    class Bool < Base
      def parse(value)
        case value
        when 'true', true, 't', '1', 1
          true
        when 'false', false, 'f', '0', 0
          false
        else
          raise ::TypeError
        end
      end
    end
  end
end
