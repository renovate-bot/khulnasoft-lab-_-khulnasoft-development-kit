# frozen_string_literal: true

module KDK
  class VersionManager
    VERSION_FILES = {
      gitaly: 'GITALY_SERVER_VERSION',
      khulnasoft_shell: 'KHULNASOFT_SHELL_VERSION',
      workhorse: 'KHULNASOFT_WORKHORSE_VERSION'
    }.freeze

    DEFAULT_VERSIONS = {
      gitaly: 'main',
      khulnasoft_shell: 'main',
      workhorse: 'main',
      graphql_schema: 'master'
    }.freeze

    def self.fetch(name)
      return DEFAULT_VERSIONS.fetch(name, 'main') unless VERSION_FILES.key?(name)

      filename = VERSION_FILES[name]
      version_path = KDK.config.kdk_root.join('khulnasoft', filename)

      File.exist?(version_path) ? File.read(version_path).strip : DEFAULT_VERSIONS[name]
    end
  end
end
