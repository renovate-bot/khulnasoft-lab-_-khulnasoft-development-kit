# frozen_string_literal: true

module KDK
  module ConfigType
    class Settings
      def self.new(parent:, builder:, **_kwargs)
        raise KeyError unless parent.yaml.is_a?(::Hash)

        yaml = parent.yaml[builder.key] ||= {}

        Class.new(parent.settings_klass).tap do |k|
          k.class_eval(&builder.blk)
        end.new(key: builder.key, parent: parent, yaml: yaml)
      end
    end
  end
end
