# frozen_string_literal: true

module KDK
  # Services module contains individual service classes (e.g. Redis) that
  # are responsible for producing the correct command line to execute and
  # if the service should in fact be executed.
  #
  module Services
    # This are the classes in Services modules that are used as base classes for services
    SERVICE_BASE_CLASSES = %i[
      Base
      Legacy
      InvalidEnvironmentKeyError
    ].freeze

    # Return a list of class names that represent a Service
    #
    # @return [Array<Symbol>] array of class names exposing a service
    def self.all_service_names
      ::KDK::Services.constants.select { |c| ::KDK::Services.const_get(c).is_a? Class } - SERVICE_BASE_CLASSES
    end

    # Returns an Array of all services, including enabled and not
    # enabled.
    #
    # @return [Array<Class>] all services
    def self.all
      all_service_names.map do |const|
        const_get(const).new
      end
    end

    # Return the service that matches the given name
    #
    # @param [Symbol|String] name
    # @return [::KDK::Services::Base|nil] service instance
    def self.fetch(name)
      service = all_service_names.find { |srv| srv == name.to_sym }

      return unless service

      const_get(service).new
    end

    # Returns an Array of enabled services only.
    #
    # @return [Array<Class>] enabled services
    def self.enabled
      all.select(&:enabled?)
    end

    # Returns an Array of legacy services defined in +Procfile+.
    #
    # @return [Array<Class>] legacy services
    def self.legacy
      Legacy.new(KDK.root).all
    end

    # Legacy services.
    #
    # @deprecated This class will be removed when all services have been converted to KDK::Services
    # @see https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/904
    class Legacy
      Mock = Struct.new(:name, :command, :enabled, :env) do
        alias_method :enabled?, :enabled
      end

      def initialize(kdk_root)
        @procfile_path = kdk_root.join('Procfile')
      end

      # Load a list of services from Procfile
      def all
        return [] unless @procfile_path.exist?

        @procfile_path.readlines.filter_map do |line|
          line.chomp!

          name, command = line.split(': ', 2)
          next unless name && command

          commented = name.sub!(/^\s*#\s*/, '')
          delete_exec_prefix!(name, command)

          Mock.new(name, command, !commented, {})
        end
      end

      private

      def delete_exec_prefix!(service, command)
        exec_prefix = 'exec '
        abort "fatal: Procfile command for service #{service} does not start with 'exec'" unless command.start_with?(exec_prefix)

        command.delete_prefix!(exec_prefix)
      end
    end

    private_constant :Legacy
  end
end
