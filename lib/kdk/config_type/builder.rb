# frozen_string_literal: true

module KDK
  module ConfigType
    class Builder
      attr_reader :key, :klass, :blk, :kwargs

      def initialize(key:, klass:, **kwargs, &blk)
        @key = key
        @klass = klass
        @kwargs = kwargs
        @blk = blk
      end

      def ignore?
        key.start_with?('__') || key.end_with?('?')
      end

      def build(parent:)
        klass.new(parent: parent, builder: self, **kwargs)
      end
    end
  end
end
