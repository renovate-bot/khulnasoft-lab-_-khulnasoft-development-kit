# frozen_string_literal: true

module KDK
  # Utility functions related to KDK dependencies
  module Dependencies
    MissingDependency = Class.new(StandardError)

    # Is Homebrew available?
    #
    # @return boolean
    def self.homebrew_available?
      Utils.executable_exist?('brew')
    end

    # Is MacPorts available?
    #
    # @return boolean
    def self.macports_available?
      Utils.executable_exist?('port')
    end

    # Is Debian / Ubuntu APT available?
    #
    # @return boolean
    def self.linux_apt_available?
      Utils.executable_exist?('apt')
    end

    # Is Asdf is available and correctly setup?
    #
    # @return boolean
    def self.asdf_available?
      return false if config.asdf.opt_out?

      Utils.executable_exist?('asdf') || ENV.values_at('ASDF_DATA_DIR', 'ASDF_DIR').compact.any?
    end

    # Is mise available?
    #
    # @return [Boolean]
    def self.mise_available?
      config.mise.enabled? && Utils.executable_exist?('mise')
    end

    def self.bundler_loaded?
      defined? Bundler
    end

    def self.config
      KDK.config
    end
  end
end
