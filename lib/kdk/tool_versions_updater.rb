# frozen_string_literal: true

module KDK
  class ToolVersionsUpdater
    COMBINED_TOOL_VERSIONS_FILE = '.combined-tool-versions'
    RUBY_PATCHES = {
      '3.2.4' => 'https://github.com/khulnasoft-lab/khulnasoft-build-images/-/raw/d95e4efae87d5e3696f22d12a6c4e377a22f3c95/patches/ruby/3.2/thread-memory-allocations.patch',
      '3.3.7' => 'https://github.com/khulnasoft-lab/khulnasoft-build-images/-/raw/e1be2ad5ff2a0bf0b27f86ef75b73824790b4b26/patches/ruby/3.3/thread-memory-allocations.patch',
      '3.4.2' => 'https://github.com/khulnasoft-lab/khulnasoft-build-images/-/raw/d077c90c540ac99ae75c396b91dcfcb136281059/patches/ruby/3.4/thread-memory-allocations.patch'
    }.freeze

    def self.enabled_services
      # Cache the results of enabled services,
      @enabled_services ||= (KDK::Services.enabled + KDK::Services.legacy.select(&:enabled?)).map(&:name)
      # but return a copy each time to avoid side-effects.
      @enabled_services.dup
    end

    def run
      return skip_message unless should_update?

      tool_versions = collect_tool_versions
      configure_env(tool_versions)
      write_combined_file(tool_versions)
      install_tools(tool_versions)
    ensure
      cleanup
    end

    private

    def should_update?
      KDK.config.mise.enabled? || !KDK.config.asdf.opt_out?
    end

    def skip_message
      KDK::Output.info('Skipping tool versions update since neither mise nor asdf is enabled')
    end

    def collect_tool_versions
      git_fetch_version_files

      # Get all service names in the enabled list and include the required ones that are missing.
      service_names = self.class.enabled_services
      service_names.push('khulnasoft', 'khulnasoft-shell')

      services = []
      service_names.each do |name|
        config_key = name.tr('-', '_')
        repo_url = KDK.config.repositories[config_key]

        services << [name, repo_url, config_key] if repo_url
      end

      KDK::Output.info("Found #{services.size} services with repositories")

      threads = services.map do |name, repo_url, config_key|
        Thread.new do
          config = KDK.config[config_key]
          version = get_version(config)

          Thread.current[:tools] = fetch_service_tool_versions(name, repo_url, version)
        end
      end

      threads << Thread.new do
        Thread.current[:tools] = root_tool_versions
      end

      threads
        .flat_map { |thread| thread.join[:tools] }
        .select { |x| x }
        .group_by(&:first)
        .transform_values { |x| x.flat_map(&:last).uniq }
    end

    def root_tool_versions
      path = KDK.root.join('.tool-versions')

      parse_tool_versions(File.read(path))
    end

    def get_version(config)
      return 'main' unless config
      return config.__version if config.respond_to?(:__version) && config.__version
      return config.default_branch if config.respond_to?(:default_branch) && config.default_branch

      'main'
    end

    def git_fetch_version_files
      branch = KDK.config.khulnasoft.default_branch
      KDK::Shellout.new("git fetch origin #{branch}", chdir: KDK.config.khulnasoft.dir).execute
      KDK::Shellout.new("git checkout origin/#{branch} -- '*_VERSION'", chdir: KDK.config.khulnasoft.dir).execute
    end

    def http_get(url)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)

      return nil unless response.is_a?(Net::HTTPSuccess)

      response.body
    end

    def parse_tool_versions(content)
      content.each_line.flat_map do |line|
        line = line.split('#', 2).first.strip
        next if line.empty?

        tool, *version_numbers = line.split
        version_numbers.map { |version| [tool, version] }
      end
    end

    def fetch_service_tool_versions(name, repo_url, version_or_branch)
      path = repo_url.sub('.git', '')
      url = "#{path}/-/raw/#{version_or_branch}/.tool-versions"

      response = http_get(url)

      if response.nil?
        KDK::Output.debug("Failed to fetch .tool-versions for '#{name}' from #{repo_url}")
        return nil
      end

      parse_tool_versions(response)
    end

    def write_combined_file(tool_versions)
      combined_content = tool_versions.filter_map do |tool, versions|
        "#{tool} #{versions.join(' ')}"
      end.join("\n").concat("\n")

      File.write(COMBINED_TOOL_VERSIONS_FILE, combined_content)
      KDK::Output.debug("Combined tool versions content:\n#{combined_content}")
    end

    def configure_env(tool_versions)
      rust_version = tool_versions['rust']&.first

      if KDK.config.mise.enabled?
        ENV['MISE_OVERRIDE_TOOL_VERSIONS_FILENAMES'] = COMBINED_TOOL_VERSIONS_FILE
        ENV['MISE_RUST_VERSION'] = rust_version if rust_version
      else
        ENV['ASDF_DEFAULT_TOOL_VERSIONS_FILENAME'] = COMBINED_TOOL_VERSIONS_FILE
        ENV['ASDF_RUST_VERSION'] = rust_version if rust_version
      end

      ENV['RUST_WITHOUT'] = 'rust-docs' if rust_version
    end

    def install_tools(tool_versions)
      install_rust(tool_versions['rust'])

      threads = []
      threads << Thread.new { install_ruby(tool_versions['ruby']) }
      threads << Thread.new { install_node(tool_versions['nodejs']) }

      threads.each(&:join)

      install_remaining_tools

      KDK::Output.success('Successfully updated tool versions!')
    rescue StandardError => e
      KDK::Output.error("Failed to update tool versions: #{e.message}")
    end

    def install_rust(versions)
      return if versions.nil? || versions.empty?

      version = versions.first
      run_install('rust', version)
    end

    def install_ruby(versions)
      return if versions.nil? || versions.empty?

      versions.each do |version|
        ENV['MISC_RUBY_APPLY_PATCHES'] = RUBY_PATCHES[version] if RUBY_PATCHES[version]
        run_install('ruby', version)
      end

      KDK::Shellout.new('asdf reshim ruby').execute unless KDK.config.asdf.opt_out?
    end

    def install_node(versions)
      return if versions.nil? || versions.empty?

      versions.each do |version|
        run_install('nodejs', version)
      end
    end

    def install_remaining_tools
      run_install
    end

    def run_install(tool = nil, version = nil)
      base_command = tool_version_manager == 'mise' ? 'mise install -y' : 'asdf install'
      cmd = tool && version ? "#{base_command} #{tool} #{version}" : base_command

      KDK::Shellout.new(cmd, chdir: KDK.root).execute
    end

    def tool_version_manager
      KDK.config.mise.enabled? ? 'mise' : 'asdf'
    end

    def cleanup
      FileUtils.rm_f(COMBINED_TOOL_VERSIONS_FILE)

      if KDK.config.mise.enabled?
        ENV.delete('MISE_OVERRIDE_TOOL_VERSIONS_FILENAMES')
        ENV.delete('MISE_RUST_VERSION')
      else
        ENV.delete('ASDF_DEFAULT_TOOL_VERSIONS_FILENAME')
        ENV.delete('ASDF_RUST_VERSION')
      end

      ENV.delete('RUST_WITHOUT')
    end
  end
end
