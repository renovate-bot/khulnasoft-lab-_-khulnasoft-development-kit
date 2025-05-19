# frozen_string_literal: true

module KDK
  module PackageConfig
    PROJECTS = {
      gitaly: {
        package_name: 'gitaly',
        project_path: 'gitaly',
        upload_path: 'build',
        download_paths: ['gitaly/_build/bin', 'khulnasoft/tmp/tests/gitaly/_build/bin'],
        platform_specific: true
      },
      khulnasoft_shell: {
        package_name: 'khulnasoft-shell',
        project_path: 'khulnasoft-shell',
        upload_path: 'build',
        download_paths: ['khulnasoft-shell/bin'],
        platform_specific: true
      },
      workhorse: {
        package_name: 'workhorse',
        project_path: 'khulnasoft/workhorse',
        upload_path: 'build',
        download_paths: ['khulnasoft/workhorse'],
        platform_specific: true
      },
      graphql_schema: {
        package_name: 'graphql-schema',
        project_path: 'khulnasoft',
        upload_path: 'tmp/tests/graphql', # Uploaded in khulnasoft-org/khulnasoft
        download_paths: ['khulnasoft/tmp/tests/graphql'],
        platform_specific: false
      }
    }.freeze

    def self.project(name)
      data = PROJECTS[name]
      version = KDK::VersionManager.fetch(name)
      project_path = KDK.config.kdk_root.join(data[:project_path])
      download_paths = data[:download_paths].map { |path| KDK.config.kdk_root.join(path) }

      data.merge(
        package_path: "#{data[:package_name]}.tar.gz",
        package_version: version,
        project_path: project_path,
        upload_path: project_path.join(data[:upload_path]),
        download_paths: download_paths
      )
    end
  end
end
