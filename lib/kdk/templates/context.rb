# frozen_string_literal: true

module KDK
  module Templates
    # Context to which a template is run
    #
    # This includes all available helper methods and data
    class Context
      attr_reader :locals

      def initialize(**locals)
        @locals = locals
      end

      # Return path to KDK root directory
      #
      # @return [String] root path
      def kdk_root
        config.kdk_root
      end

      # Return config data structure
      #
      # @return [KDK::Config] config data
      def config
        KDK.config
      end

      # Returns an instance of the service that matches the given name
      #
      # @return [KDK::Services::Base|nil]
      def service(name)
        KDK::Services.fetch(name) || raise("No service named #{name} found")
      end

      def context_bindings
        binding
      end

      private

      def method_missing(method_name)
        return locals[method_name] if locals.include?(method_name)

        super
      end

      def respond_to_missing?(symbol, include_all)
        locals.any?(symbol) || super
      end
    end
  end
end
