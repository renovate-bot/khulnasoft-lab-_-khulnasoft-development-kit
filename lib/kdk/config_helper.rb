# frozen_string_literal: true

module KDK
  # Reads the version file and returns its version or an empty string if it doesn't exist.
  module ConfigHelper
    extend self

    def version_from(config, path)
      full_path = config.kdk_root.join(path)
      return '' unless full_path.exist?

      version = full_path.read.chomp
      process_version(version)
    end

    private

    def process_version(version)
      # Returns commit hash as is
      return version if version.length == 40

      "v#{version}"
    end
  end
end
