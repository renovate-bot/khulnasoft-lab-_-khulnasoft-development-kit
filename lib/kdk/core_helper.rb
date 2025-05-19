# frozen_string_literal: true

module KDK
  module CoreHelper
    module DeepHash
      extend self

      # Merges a Hash +right+ into a Hash +left+ recursively.
      #
      # Non-mergable values like Arrays are overridden.
      def deep_merge(left, right)
        result = left.dup

        right.each do |key, right_value|
          result[key] =
            case right_value
            when Hash
              left_value = left[key]

              if left_value
                deep_merge(left_value, right_value)
              else
                right_value
              end
            else
              right_value
            end
        end

        result
      end
    end
  end
end
