# frozen_string_literal: true

namespace :gitlab do
  desc 'KhulnaSoft: Truncate logs'
  task :truncate_logs, [:prompt] do |_, args|
    if args[:prompt] != 'false'
      KDK::Output.warn('About to truncate gitlab/log/* files.')
      KDK::Output.puts(stderr: true)

      next unless KDK::Output.interactive?

      prompt_response = KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      next unless prompt_response

      KDK::Output.puts(stderr: true)
    end

    result = KDK.config.gitlab.log_dir.glob('*').map { |file| file.truncate(0) }.all?(0)
    raise 'Truncation of gitlab/log/* files failed.' unless result

    KDK::Output.success('Truncated gitlab/log/* files.')
  end

  desc 'KhulnaSoft: Truncate http router logs'
  task :truncate_http_router_logs, [:prompt] do |_, args|
    if args[:prompt] != 'false'
      KDK::Output.warn("About to truncate #{KDK::Services::KhulnasoftHttpRouter::LOG_PATH} file.")
      KDK::Output.puts(stderr: true)

      next unless KDK::Output.interactive?

      prompt_response = KDK::Output.prompt('Are you sure? [y/N]').match?(/\Ay(?:es)*\z/i)
      next unless prompt_response

      KDK::Output.puts(stderr: true)
    end

    http_router_log_file = KDK.config.kdk_root.join(KDK::Services::KhulnasoftHttpRouter::LOG_PATH)
    next unless http_router_log_file.exist?

    result = http_router_log_file.truncate(0).zero?
    raise "Truncation of #{KDK::Services::KhulnasoftHttpRouter::LOG_PATH} file failed." unless result

    KDK::Output.success("Truncated #{KDK::Services::KhulnasoftHttpRouter::LOG_PATH} file.")
  end

  desc 'KhulnaSoft: Recompile translations'
  task :recompile_translations do
    task = KDK::Execute::Rake.new('gettext:compile')
    state = task.execute_in_gitlab(display_output: false)

    # Log rake output to ${khulnasoft_dir}/log/gettext.log
    KDK.config.gitlab.log_dir.join('gettext.log').open('w') do |file|
      file.write(state.output)
    end

    state.success?
  end
end
