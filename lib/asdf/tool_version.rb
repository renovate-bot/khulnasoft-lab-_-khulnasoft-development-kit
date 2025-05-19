# frozen_string_literal: true

require 'pathname'

module Asdf
  class ToolVersion
    UninstallFailedError = Class.new(StandardError)

    attr_reader :name, :version

    def initialize(name, version)
      @name = name
      @version = version
    end

    def uninstall!
      sh = KDK::Shellout.new("asdf uninstall #{name} #{version}").execute
      raise(UninstallFailedError) unless sh.success?

      true
    end
  end
end
