# frozen_string_literal: true

namespace :mise do
  desc 'Migrate from asdf to mise'
  task :migrate do
    AsdfToMise.new.execute
  end
end

class AsdfToMise
  def execute
    disable_asdf
    enable_mise
    install_git_hooks
    remove_bootstrap_cache
    re_bootstrap
    replace_asdf_with_mise_in_shell_configs
    display_success_message
  end

  private

  def disable_asdf
    KDK::Output.info('Opting out of asdf...')
    KDK::Command::Config.new.run(['set', 'asdf.opt_out', 'true'])
  end

  def replace_asdf_with_mise_in_shell_configs
    @updated_shell_configs = []
    @backup_paths = []

    mise_path = `which mise 2>/dev/null`.strip
    mise_path = 'mise' if mise_path.empty?

    shell_configs = {
      '~/.bashrc' => { asdf: 'asdf.sh', mise: "eval \"$(#{mise_path} activate bash)\"" },
      '~/.zshrc' => { asdf: 'asdf.sh', mise: "eval \"$(#{mise_path} activate zsh)\"" },
      '~/.config/fish/config.fish' => { asdf: 'asdf.fish', mise: 'mise activate fish' },
      '~/.config/elvish/rc.elv' => { asdf: 'asdf.elv', mise: 'mise activate elvish' },
      '~/.config/nushell/config.nu' => { asdf: 'asdf.nu', mise: 'mise activate nu' }
    }

    shell_configs.each do |path, scripts|
      full_path = File.expand_path(path)
      next unless File.file?(full_path)

      content = File.read(full_path)
      original = content.dup

      mise_line = "# Added by KDK bootstrap\n#{scripts[:mise]}"
      pattern = %r{# Added by KDK bootstrap\n(\.|source) .*?/\.asdf/#{Regexp.escape(scripts[:asdf])}}

      next unless content.match?(pattern)

      content = content.gsub(pattern, mise_line)
      next if content == original

      backup_path = "#{full_path}.#{Time.now.strftime('%Y%m%d%H%M%S')}.bak"
      FileUtils.cp(full_path, backup_path)
      @backup_paths << backup_path

      File.write(full_path, content)
      @updated_shell_configs << full_path
    rescue StandardError => e
      KDK::Output.error("Failed to update #{full_path}: #{e.message}")
    end
  end

  def enable_mise
    KDK::Output.info('Enabling mise...')
    KDK::Command::Config.new.run(['set', 'mise.enabled', 'true'])
  end

  def install_git_hooks
    KDK::Output.info('Installing Git hooks...')
    run_command('lefthook install', 'lefthook install failed!')
  end

  def remove_bootstrap_cache
    KDK::Output.info('Removing cached bootstrap files...')
    cache_path = File.join(KDK.config.kdk_root, '.cache')
    %w[.kdk_bootstrapped .kdk_platform_setup].each do |file|
      FileUtils.rm_f(File.join(cache_path, file))
    end
  end

  def re_bootstrap
    KDK::Output.info('Running `bin/kdk-shell support/bootstrap` to install mise and dependencies...')
    run_command('bin/kdk-shell support/bootstrap', 'bin/kdk-shell support/bootstrap failed!')
  end

  def display_success_message
    KDK::Output.success('Migration from asdf to mise is almost complete!')
    KDK::Output.puts

    if @updated_shell_configs && !@updated_shell_configs.empty?
      KDK::Output.notice('Shell config files updated:')
      KDK::Output.puts("   - #{@updated_shell_configs.join("\n   - ")}")
      KDK::Output.puts
      KDK::Output.notice('Backups of your original shell config files were created:')
      KDK::Output.puts("   - #{@backup_paths.join("\n   - ")}")
      KDK::Output.puts
    end

    KDK::Output.notice('Next steps:')
    KDK::Output.notice('1. Please restart your terminal.')
    KDK::Output.notice('2. Afterward, run this command:')
    KDK::Output.puts('   kdk reconfigure && kdk update')
    KDK::Output.puts
    KDK::Output.notice('If you encounter any issues with mise, see our troubleshooting guide: https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/doc/troubleshooting/mise.md')
  end

  def run_command(command, error_message)
    if KDK::Dependencies.bundler_loaded?
      Bundler.with_unbundled_env do
        sh = KDK::Shellout.new(command.split).execute
        raise StandardError, error_message unless sh.success?
      end
    else
      sh = KDK::Shellout.new(command.split).execute
      raise StandardError, error_message unless sh.success?
    end
  end
end
