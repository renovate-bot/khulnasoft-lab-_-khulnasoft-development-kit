# frozen_string_literal: true

require 'json'

module KDK
  module ConfigType
    class Hash < Base
      include Mergable
      include CoreHelper::DeepHash

      def parse(value)
        if value.is_a?(::String)
          begin
            return JSON.parse(value)
          rescue JSON::ParserError => e
            raise StandardErrorWithMessage, e.message
          end
        end

        value.to_h
      end

      def dump!(user_only: false)
        user_only ? @user_value : super
      end

      private

      def mergable_merge(fetched, default)
        deep_merge(default, Hash(fetched))
      end
    end
  end
end
