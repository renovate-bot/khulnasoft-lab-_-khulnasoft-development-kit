# frozen_string_literal: true

require 'fileutils'
require 'rubygems/package'
require 'zlib'
require 'net/http'
require 'uri'
require 'tmpdir'

require_relative '../kdk'

module KDK
  class PackageHelper
    API_V4_URL = 'https://gitlab.com/api/v4'
    KDK_PROJECT_ID = '74823'
    SUPPORTED_ARCHS = %w[darwin-arm64 linux-amd64 linux-arm64].freeze
    EXCLUDED_FILES = %w[build/metadata.txt build/checksums.txt].freeze
    FALLBACK_BRANCHES = %w[main master].freeze

    def self.supported_os_arch?(os_arch_name = KDK::Machine.package_platform)
      SUPPORTED_ARCHS.include?(os_arch_name)
    end

    attr_reader :package_basename, :package_name, :package_path, :package_version, :project_path, :upload_path, :download_paths, :platform_specific, :project_id, :token

    def initialize(package:, project_id: KDK_PROJECT_ID, token: ENV.fetch('CI_JOB_TOKEN', ''))
      config = KDK::PackageConfig.project(package) { raise "Unknown package: #{package}" }

      @platform_specific = config[:platform_specific]
      @package_basename = config[:package_name]
      @package_name = @platform_specific ? "#{@package_basename}-#{KDK::Machine.package_platform}" : @package_basename
      @package_path = config[:package_path]
      @package_version = ENV['PACKAGE_VERSION'] || config[:package_version]
      @project_path = config[:project_path]
      @upload_path = config[:upload_path]
      @download_paths = config[:download_paths]
      @project_id = project_id
      @token = token
    end

    def create_package
      File.open(package_path, 'wb') do |file|
        Zlib::GzipWriter.wrap(file) do |gzip|
          Gem::Package::TarWriter.new(gzip) do |tar|
            upload_path.find do |path|
              next if path == upload_path

              if path.directory?
                tar.mkdir(path.to_s, path.stat.mode)
              else
                add_file_to_tar(tar, path)
              end
            end
          end
        end
      end

      KDK::Output.success("Package created at #{package_path}")
    rescue StandardError => e
      raise "Package creation failed: #{e.message}"
    end

    def upload_package
      create_package

      base_uri = "#{API_V4_URL}/projects/#{project_id}/packages/generic/#{package_name}"

      versions = [package_version, 'latest']

      versions.each do |version|
        uri = URI.parse("#{base_uri}/#{version}/#{File.basename(package_path)}")
        request = Net::HTTP::Put.new(uri)
        request['JOB-TOKEN'] = token
        request.body = File.read(package_path)

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end

        raise "Upload failed for version '#{version}': #{response.body}" unless response.is_a?(Net::HTTPSuccess)

        KDK::Output.success("Package uploaded successfully to #{uri}")
      end
    end

    def download_package
      if platform_specific && !KDK::PackageHelper.supported_os_arch?
        KDK::Output.info("Unsupported OS or architecture detected in #{KDK::Machine.package_platform}.
          To continue, please enable local compilation and then update by running `kdk config set #{package_basename}.skip_compile false && kdk update`.
        ")
        return
      end

      return KDK::Output.success("No changes detected in #{project_path}, skipping package download and extraction.") if current_commit_sha == stored_commit_sha

      uri = URI.parse("#{API_V4_URL}/projects/#{project_id}/packages/generic/#{package_name}/#{package_version}/#{File.basename(package_path)}")
      KDK::Output.info("Downloading package from #{uri}")

      response = Net::HTTP.get_response(uri)

      if response.is_a?(Net::HTTPNotFound)
        KDK::Output.warn("Package not found for version '#{package_version}', trying 'latest' instead.")

        uri = URI.parse("#{API_V4_URL}/projects/#{project_id}/packages/generic/#{package_name}/latest/#{File.basename(package_path)}")
        KDK::Output.info("Retrying download from #{uri}")

        response = Net::HTTP.get_response(uri)
      end

      raise "Download failed: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      File.write(package_path, response.body)
      KDK::Output.success("Package downloaded successfully to #{package_path}")

      @download_paths.each { |path| extract_package(path) }

      FileUtils.rm_f(package_path)
      store_commit_sha(current_commit_sha)
    end

    def extract_package(destination_path)
      destination_path.mkpath

      Dir.mktmpdir do |tmp_dir|
        tmp_download_path = Pathname.new(tmp_dir)

        File.open(package_path, 'rb') do |file|
          Zlib::GzipReader.wrap(file) do |gzip|
            Gem::Package::TarReader.new(gzip) do |tar|
              tar.each do |entry|
                extract_entry(entry, tmp_download_path)
              end
            end
          end
        end

        copy_entries(tmp_download_path, destination_path)
        KDK::Output.success("Package extracted successfully to #{destination_path}")
      end
    end

    private

    def add_file_to_tar(tar, file_path)
      stat = file_path.stat
      tar.add_file_simple(file_path.to_s, stat.mode, stat.size) do |io|
        io.write(file_path.binread)
        print '.'
      end
    end

    def copy_entries(source_dir, destination_dir)
      source_dir.find do |entry|
        next if entry.directory? && entry.find(&:file?).nil?

        destination_path = destination_dir.join(entry.relative_path_from(source_dir))

        FileUtils.mkdir_p(destination_path.dirname)
        FileUtils.cp_r(entry, destination_path, remove_destination: true)
      end
    end

    def current_commit_sha
      Shellout.new(%W[git -C #{project_path} rev-parse HEAD]).run
    end

    def extract_entry(entry, destination_path)
      return if entry.full_name.include?('..')

      target_path = destination_path.join(File.basename(entry.full_name))
      parent_dir = target_path.dirname

      if entry.directory?
        FileUtils.mkdir_p(parent_dir, mode: entry.header.mode)
        return
      end

      return unless entry.file?

      return if EXCLUDED_FILES.any? { |excluded| entry.full_name.end_with?(excluded) }

      File.binwrite(target_path, entry.read)
      File.chmod(entry.header.mode, target_path)
    end

    def sha_file_path
      File.join(sha_file_root, '.cache', ".#{package_name.gsub(/[^a-z0-9]+/i, '_')}_commit_sha")
    end

    def sha_file_root
      KDK.config.kdk_root
    end

    def store_commit_sha(commit_sha)
      FileUtils.mkdir_p(File.dirname(sha_file_path))

      File.write(sha_file_path, commit_sha)
    end

    def stored_commit_sha
      return nil unless File.exist?(sha_file_path)

      File.read(sha_file_path).chomp
    end
  end
end
