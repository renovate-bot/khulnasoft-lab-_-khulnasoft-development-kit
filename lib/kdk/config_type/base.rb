# frozen_string_literal: true

module KDK
  module ConfigType
    class Base
      extend ::Forwardable

      attr_reader :builder, :parent, :value, :user_value

      def_delegators :builder, :key, :blk

      def initialize(parent:, builder:)
        @parent = parent
        @builder = builder

        self.value = read_value
      end

      def default_value
        parent.instance_eval(&blk) if blk
      end

      def value=(val)
        @value = parse(val)
      rescue StandardErrorWithMessage => e
        raise e, "Value '#{val}' for setting '#{slug}' is not a valid #{type} - #{e.message}."
      rescue ::TypeError, ::NoMethodError
        raise ::TypeError, "Value '#{val}' for setting '#{slug}' is not a valid #{type}."
      end

      def user_defined?
        !!defined?(@user_value)
      end

      def validate!
        true # Validated in #value=
      end

      def dump!(*)
        value
      end

      def slug
        [parent.slug, key].compact.join('.')
      end

      def root
        parent&.root || self
      end
      alias_method :config, :root

      private

      def read_value
        @user_value = parent.yaml.fetch(key)
      rescue KeyError
        default_value
      end

      def type
        self.class.name.split('::').last.downcase
      end
    end
  end
end
