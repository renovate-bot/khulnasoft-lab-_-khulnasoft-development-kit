# frozen_string_literal: true

module KDK
  module ConfigType
    class SettingsArray < Base
      extend ::Forwardable

      ArrayAccessError = Class.new(StandardError)

      attr_accessor :size, :elems
      alias_method :value, :itself
      def_delegators :@elems, :[], :count, :each, :each_with_index, :fetch,
        :first, :last, :map, :select

      def initialize(parent:, builder:, size:)
        @size = size
        super(parent: parent, builder: builder)
      end

      def length
        @length ||= case size
                    when Proc
                      parent.instance_exec(&size)
                    when Numeric
                      size
                    when nil
                      yaml_array = parent.yaml[key] ||= []
                      yaml_array.length
                    else
                      raise ::ArgumentError, "size for #{slug} must be a number, a proc, or nil (dynamic size)"
                    end
      end

      def dig(*slugs)
        slugs, index = extract_slugs_and_index(*slugs)
        return value[index] if slugs.empty?

        value[index].dig(*slugs)
      end

      def user_defined?(*slugs)
        # Without any slugs we want to behave like `Base#user_defined?`
        return super() if slugs.empty?
        # Do we have user defined values?
        return false unless super()

        slugs, index = extract_slugs_and_index(*slugs)
        return !!@user_value[index] if slugs.empty?

        @user_value[index].user_defined?
      end

      def bury!(*slugs, new_value)
        slugs, index = extract_slugs_and_index(*slugs)

        value[index].bury!(*slugs, new_value)
      end

      def to_s
        dump!.to_yaml
      end

      def read_value
        user_defined = []
        array = parent.yaml[key] ||= []
        original_array_size = array.size

        @elems = ::Array.new(length) do |i|
          yaml = array[i] ||= {}

          value = Class.new(parent.settings_klass).tap do |k|
            k.integer(:__index) { i }
            k.class_exec(i, &blk)
            # # Trickery to get a block argument at instance level (don't ask me how)
            # k.class_exec do
            #   instance_exec(i, &blk)
            # end
          end.new(key: i, parent: self, yaml: yaml)

          user_defined << value if i < original_array_size

          value
        end

        @user_value = user_defined if user_defined.any?

        @elems
      end

      def dump!(user_only: false)
        if user_only
          (@user_value || elems).map { |e| e.dump!(user_only: true) }
        else
          elems.map(&:dump!)
        end
      end

      def parse(value)
        value
      end

      def inspect
        "#<#{self.class.name} slug:#{slug}, length:#{length}>"
      end

      private

      def extract_slugs_and_index(*slugs)
        slugs = slugs.first.to_s.split('.') if slugs.one?
        index = Integer(slugs.shift, exception: false)

        raise ArrayAccessError, "length on #{slug} must be a positive number" if index.nil? || index.negative?
        raise ArrayAccessError, "#{slug} only has #{length} entries" if index >= length

        [slugs, index]
      end
    end
  end
end
