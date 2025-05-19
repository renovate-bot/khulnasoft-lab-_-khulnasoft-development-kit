# frozen_string_literal: true

module Asdf
  class Tool
    attr_reader :name
    attr_accessor :versions

    def initialize(name, versions)
      @name = name
      @versions = versions
    end

    def default_version
      default_tool_version.version
    end

    def default_tool_version
      # tool_versions.first is in the format of the following, where we only
      # want the instance of ToolVersion:
      #
      # {"version" => Asdf::ToolVersion}
      #
      tool_versions.first[1]
    end

    def tool_versions
      @tool_versions ||= versions.each_with_object({}) do |version, all|
        all[version] = ToolVersion.new(name, version)
      end
    end
  end
end
