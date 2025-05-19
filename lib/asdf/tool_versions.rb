# frozen_string_literal: true

require 'pathname'

module Asdf
  class ToolVersions
    def default_tool_version_for(tool)
      tool_versions[tool]&.default_tool_version
    end

    def default_version_for(tool)
      default_tool_version_for(tool)&.version
    end

    def unnecessary_software_to_uninstall?
      work_to_do?(output: false)
    end

    def uninstall_unnecessary_software!(prompt: true)
      return true unless work_to_do?

      if prompt
        inform
        return true unless confirm?
      end

      failed_to_uninstall = {}

      unnecessary_installed_versions_of_software.each do |name, versions|
        KDK::Output.print "Uninstalling #{name} "

        versions.each_with_index do |(version, tool_version), i|
          KDK::Output.print ', ' if i.positive?
          KDK::Output.print version

          begin
            tool_version.uninstall!
          rescue ToolVersion::UninstallFailedError
            failed_to_uninstall[name] ||= []
            failed_to_uninstall[name] << version
          end
        end

        icon = if failed_to_uninstall.empty?
                 :success
               elsif failed_to_uninstall.count == versions.count
                 :error
               else
                 :warning
               end

        KDK::Output.puts(" #{KDK::Output.icon(icon)}")
      end

      return true if failed_to_uninstall.empty?

      KDK::Output.puts(stderr: true)
      KDK::Output.warn("Failed to uninstall the following:\n\n")
      failed_to_uninstall.each do |name, versions|
        KDK::Output.puts("#{name} #{versions.join(', ')}")
      end

      false
    end

    def unnecessary_installed_versions_of_software
      installed_versions_of_wanted_software.each_with_object({}) do |(name, versions), unncessary_software|
        versions.each do |version, tool_version|
          next if wanted_software[name][version]

          unncessary_software[name] ||= {}
          unncessary_software[name][version] = tool_version
        end
      end
    end

    private

    def config
      KDK.config
    end

    def asdf_opt_out?
      config.asdf.opt_out?
    end

    def inform
      KDK::Output.warn('About to uninstall the following asdf software:')
      KDK::Output.puts(stderr: true)

      unnecessary_installed_versions_of_software.each do |name, versions|
        KDK::Output.puts("#{name} #{versions.keys.join(', ')}")
      end

      KDK::Output.puts(stderr: true)
    end

    def work_to_do?(output: true)
      if asdf_opt_out?
        KDK::Output.info('Skipping because asdf.opt_out is set to true.') if output
        return false
      elsif !asdf_data_installs_dir.exist?
        KDK::Output.info("Skipping because '#{asdf_data_installs_dir}' does not exist.") if output
        return false
      elsif unnecessary_installed_versions_of_software.empty?
        KDK::Output.info('No unnecessary asdf software to uninstall.') if output
        return false
      end

      true
    end

    def confirm?
      return true if ENV.fetch('KDK_ASDF_UNINSTALL_UNNECESSARY_SOFTWARE_CONFIRM', 'false') == 'true' || !KDK::Output.interactive?

      KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
    end

    def raw_tool_versions_lines
      KDK.root.glob('{.tool-versions,{*,*/*}/.tool-versions}').each_with_object([]) do |path, lines|
        lines.concat(File.readlines(path))
      end
    end

    def tool_versions
      @tool_versions ||= raw_tool_versions_lines.each_with_object({}) do |line, all|
        match = line.chomp.match(/\A(?<name>\w+) (?<versions>[\d. ]+)\z/)
        next unless match

        new_versions = match[:versions].split

        if all[match[:name]]
          all[match[:name]].versions |= new_versions
        else
          all[match[:name]] = Tool.new(match[:name], new_versions)
        end
      end
    end

    def wanted_software
      tool_versions.transform_values(&:tool_versions)
    end

    def asdf_data_dir
      @asdf_data_dir ||= Pathname.new(ENV.fetch('ASDF_DATA_DIR', File.join(Dir.home, '.asdf')))
    end

    def asdf_data_installs_dir
      @asdf_data_installs_dir ||= asdf_data_dir.join('installs')
    end

    def asdf_install_dirs_for(name)
      asdf_data_installs_dir.join(name).glob('*')
    end

    def installed_versions_of_wanted_software
      wanted_software.each_with_object({}) do |(name, _), installed_software|
        asdf_install_dirs_for(name).each do |dir|
          version = dir.basename.to_s
          installed_software[name] ||= {}
          installed_software[name][version] = ToolVersion.new(name, version)
        end
      end
    end
  end
end
