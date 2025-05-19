# frozen_string_literal: true

module KDK
  module Services
    InvalidEnvironmentKeyError = Class.new(StandardError)

    # @abstract Base class to be used by individual service classes.
    #
    class Base
      def initialize
        validate_env_keys!
        validate!
      end

      # Name of the service
      #
      # @abstract to be implemented by the subclass
      # @return [String] name
      def name
        raise NotImplementedError
      end

      # Command to execute the service
      #
      # @abstract to be implemented by the subclass
      # @return [String] command
      def command
        raise NotImplementedError
      end

      # Message to display when the service is ready.
      #
      # By default, no ready message is shown.
      #
      # @return [nil, String] ready_message
      def ready_message
        nil
      end

      # Is service enabled?
      #
      # @abstract to be implemented by the subclass
      # @return [Boolean] whether is enabled or not
      def enabled?
        raise NotImplementedError
      end

      # Validate the configuration.
      #
      # @raise [ConfigSettings::UnsupportedConfiguration] Indicate configuration conflicts.
      def validate!; end

      # Environment variables
      #
      # @return [Hash] a hash of environment variables that need to be set for
      # this service.
      def env
        {}
      end

      private

      def validate_env_keys!
        env.reject { |k, _| k =~ /^[A-Z_]+$/ }.tap do |invalid|
          break unless invalid.any?

          raise InvalidEnvironmentKeyError, "Invalid environment keys for '#{name}': #{invalid.keys}"
        end
      end

      def config
        KDK.config
      end
    end
  end
end
