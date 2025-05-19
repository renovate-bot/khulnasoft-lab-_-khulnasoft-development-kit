# frozen_string_literal: true

require 'yaml'
require 'forwardable'
require 'utils'

module KDK
  class ConfigSettings
    extend ::Forwardable

    SettingUndefined = Class.new(StandardError)
    UnsupportedConfiguration = Class.new(StandardError)
    YamlModified = Class.new(StandardError)

    attr_reader :parent, :yaml, :key

    def_delegators :'self.class', :attributes

    class << self
      attr_accessor :attributes

      def load_from_file
        Persisted.new(self)
      end

      def anything(key, &blk)
        def_attribute(key, ConfigType::Anything, &blk)
      end

      def array(key, merge: false, &blk)
        def_attribute(key, ConfigType::Array, merge: merge, &blk)
      end

      def hash_setting(key, merge: false, &blk)
        def_attribute(key, ConfigType::Hash, merge: merge, &blk)
      end

      def bool(key, &blk)
        def_attribute(key, ConfigType::Bool, &blk)
        alias_method :"#{key}?", key
      end

      def integer(key, &blk)
        def_attribute(key, ConfigType::Integer, &blk)
      end

      def port(key, service_name, &blk)
        def_attribute(key, ConfigType::Port, service_name: service_name, &blk)
      end

      def path(key, &blk)
        def_attribute(key, ConfigType::Path, &blk)
      end

      def string(key, &blk)
        def_attribute(key, ConfigType::String, &blk)
      end

      def settings(key, &blk)
        def_attribute(key, ConfigType::Settings, &blk)
      end

      def settings_array(key, size: nil, &blk)
        def_attribute(key, ConfigType::SettingsArray, size: size, &blk)
      end

      private

      def def_attribute(key, klass, **kwargs, &blk)
        key = key.to_s
        self.attributes ||= {} # Using a hash to ensure uniqueness on key
        self.attributes[key] = ConfigType::Builder.new(key: key, klass: klass, **kwargs, &blk)

        define_method(key) do
          build(key).value
        end
      end
    end

    def initialize(yaml: {}, key: nil, parent: nil)
      @yaml = yaml
      @key = key
      @parent = parent
    end

    def validate!
      attributes.each_value do |attribute|
        next if attribute.ignore?

        attribute.build(parent: self).validate!
      end

      nil
    end

    def dump!(user_only: false)
      attributes.values.sort_by(&:key).each_with_object({}) do |attribute, result|
        # We don't dump a config if it:
        #  - starts with a double underscore (intended for internal use)
        #  - is a ? method (always has a non-? counterpart)
        next if attribute.ignore?

        attr_value = attribute.build(parent: self)
        next if user_only && !attr_value.user_defined?

        result[attribute.key] = attr_value.dump!(user_only: user_only)
      end
    end

    def dump_as_yaml
      dump!.to_yaml
    end

    def find_executable!(bin)
      Utils.find_executable(bin)
    end

    def user_defined?(*slugs)
      if slugs.any?
        slugs = slugs.first.to_s.split('.') if slugs.one?
        key = slugs.shift

        return build(key).user_defined?(*slugs)
      end

      attributes.values.any? do |attribute|
        next if attribute.ignore?

        attribute.build(parent: self).user_defined?
      end
    end

    def fetch(slug, *args)
      raise ::ArgumentError, %[Wrong number of arguments (#{args.count + 1} for 1..2)] if args.count > 1

      return public_send(slug) if respond_to?(slug) # rubocop:disable KhulnasoftSecurity/PublicSend

      raise SettingUndefined, %(Could not fetch the setting '#{slug}' in '#{self.slug || '<root>'}') if args.empty?

      args.first
    end

    def [](slug)
      fetch(slug, nil)
    end

    def dig(*slugs)
      slugs = slugs.first.to_s.split('.') if slugs.one?

      value = fetch(slugs.shift)

      return value if slugs.empty?

      value.dig(*slugs)
    end

    def bury!(*slugs, new_value)
      slugs = slugs.first.to_s.split('.') if slugs.one?
      key = slugs.shift

      if slugs.empty?
        setting = build(key)
        setting.value = new_value
        yaml[key] = setting.value # Sanitize
      else
        fetch(key).bury!(*slugs, new_value)
      end
    end

    def bury_multiple!(key_value_pairs)
      key_value_pairs.each do |key, value|
        bury!(key, value)
      end
    end

    def config_file_protected?(target)
      return false if kdk.overwrite_changes

      kdk.protected_config_files&.any? { |pattern| File.fnmatch(pattern, target) }
    end

    def slug
      return nil unless parent

      [parent.slug, key].compact.join('.')
    end

    def root
      parent&.root || self
    end
    alias_method :config, :root

    def inspect
      return "#<#{self.class.name}>" if self.class.name

      "#<KDK::ConfigSettings slug:#{slug}>"
    end

    def to_s
      dump!.to_yaml
    end

    alias_method :value, :itself

    # Provide a shorter form for `config.setting.enabled` as `config.setting?`
    def method_missing(method_name, *args, &blk)
      enabled = enabled_value(method_name)

      return super if enabled.nil?

      enabled
    end

    def respond_to_missing?(method_name, include_private = false)
      !enabled_value(method_name).nil? || super
    end

    def settings_klass
      ::KDK::ConfigSettings
    end

    def port_manager
      # Only the root should hold the PortManager
      return root.port_manager if parent

      @port_manager ||= PortManager.new(config: self)
    end

    private

    def attribute(key)
      attributes.fetch(key) do |k|
        raise SettingUndefined, %(Could not fetch attributes for '#{k}' in '#{slug || '<root>'}')
      end
    end

    def build(key)
      attribute(key).build(parent: self)
    end

    def enabled_value(method_name)
      return nil unless method_name.to_s.end_with?('?')

      chopped_name = method_name.to_s.chop.to_sym
      fetch(chopped_name, nil)&.fetch(:enabled, nil)
    end

    # This module contains methods to read and write a config file.
    module Persisted
      def self.new(klass)
        config = klass.new
        config.extend Persisted
        config.load_yaml!
        config
      end

      def load_yaml!
        return unless file_exist?

        assign_mtime!

        raw_yaml = File.read(self.class::FILE)
        @yaml = YAML.safe_load(raw_yaml) || {}
      end

      def save_yaml!
        if file_exist? && File.mtime(self.class::FILE) != @__yaml_mtime # rubocop:disable Style/IfUnlessModifier
          raise YamlModified, "Config YAML has been modified since it was loaded."
        end

        if file_exist?
          backup = Backup.new(self.class::FILE)
          backup.backup!
        end

        File.write(self.class::FILE, dump!(user_only: true).to_yaml)
        assign_mtime! if file_exist?

        nil
      rescue StandardError
        backup&.restore!
        raise
      end

      private

      def assign_mtime!
        @__yaml_mtime = File.mtime(self.class::FILE)
      end

      def file_exist?
        File.exist?(self.class::FILE)
      end
    end
  end
end
