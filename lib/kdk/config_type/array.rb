# frozen_string_literal: true

module KDK
  module ConfigType
    class Array < Base
      include Mergable

      def parse(value)
        if value.is_a?(::String)
          value.split(',').map(&:strip)
        else
          value.to_a
        end
      end

      private

      def mergable_merge(fetched, default)
        a = Array(fetched)

        a + (default - a)
      end
    end
  end
end
