# frozen_string_literal: true

require 'fileutils'
require 'erb'
require 'shellwords'
require 'etc'

module KDK
  module Command
    class Report < BaseCommand
      REPORT_TEMPLATE_PATH = 'lib/support/files/report_template.md.erb'
      LOG_NAMES = %w[
        khulnasoft-db-migrate
        update-make-ensure-databases-setup
        update-make-khulnasoft-topology-service-update
        reconfigure-make-kdk-reconfigure-task
        update-make-gitaly-update
        update-make-khulnasoft-translations
        reconfigure-make-khulnasoft-http-router-setup
        update-make-khulnasoft-asdf-install
        update-make-khulnasoft-workhorse-update
        reconfigure-make-khulnasoft-topology-service-setup
        update-make-khulnasoft-bundle
        update-make-khulnasoft-yarn
        reconfigure-make-postgresql
        update-make-khulnasoft-git
        update-make-postgresql
        update-kdk_bundle_install
        update-make-khulnasoft-http-router-update
        update-platform
        update-khulnasoft-git-pull
        update-make-khulnasoft-lefthook
        update-tool-versions
        update-graphql
        update-make-khulnasoft-shell-update
      ].freeze

      REPOSITORY_NAMES = %w[kdk gitaly khulnasoft].freeze
      NEW_ISSUE_URL = 'https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/new?issue[label]=~Category:KDK'
      LABELING = '/label ~type::bug ~bug::functional ~Category:KDK ~kdk-report ~group::developer tooling'
      COPY_COMMANDS = [
        'pbcopy', # macOS
        'xclip -selection clipboard', # Linux
        'xsel --clipboard --input', # Linux
        'wl-copy' # Wayland
      ].freeze

      OPEN_COMMANDS = [
        'open', # macOS
        'xdg-open' # Linux
      ].freeze

      def initialize
        @debug_info = KDK::Command::DebugInfo.new
      end

      def run(_ = [])
        @report_id = SecureRandom.uuid
        template_path = KDK.root.join(REPORT_TEMPLATE_PATH)
        KDK::Output.info('We are collecting report details, this might take a minute ...')

        # Create variables for the template
        report_json = {
          report_id: report_id,
          os_name: debug_info.os_name,
          arch: debug_info.arch,
          ruby_version: debug_info.ruby_version,
          kdk_version: debug_info.kdk_version,
          package_manager: package_manager,
          env_variables: env_variables,
          kdk_config: kdk_config,
          kdk_doctor: kdk_doctor,
          gem_env: gem_env,
          bundle_env: bundle_env,
          network_information: network_information,
          logs: logs,
          git_repositories: git_repositories,
          date_time: date_time
        }

        # Render the template
        renderer = Templates::ErbRenderer.new(template_path, report_json: report_json)
        report_content = renderer.render_to_string

        KDK::Output.puts report_content
        open_browser
        copy_clipboard(report_content)

        KDK::Output.info('This report has been copied to your clipboard.')
        KDK::Output.info('We opened the browser with a new issue, please paste this report from your clipboard into the description.')

        true
      end

      def package_manager
        if KDK.config.mise.enabled?
          "mise-en-place #{shellout('mise --version')}"
        elsif !KDK.config.asdf.opt_out?
          "asdf #{shellout('asdf version')}"
        else
          'Neither mise nor asdf is used.'
        end
      end

      def env_variables
        debug_info.env_vars.map do |var, content|
          "#{var}=#{content}"
        end.join("\n")
      end

      def kdk_config
        return 'No KDK configuration found.' unless debug_info.kdk_yml_exists?

        debug_info.kdk_yml
      end

      def kdk_doctor
        output = KDK::OutputBuffered.new
        KDK::Command::Doctor.new(out: output).run
        redact_home(output.dump.chomp)
      end

      def gem_env
        redact_home(shellout('gem env'))
      end

      def bundle_env
        redact_home(shellout('bundle env'))
      end

      def network_information
        shellout('lsof -iTCP -sTCP:LISTEN').gsub(Etc.getpwuid.name, '$USER')
      end

      def logs
        LOG_NAMES.each_with_object({}) do |service_name, logs|
          log_file_path = "log/kdk/#{log_file_name(service_name)}"
          log_file = Dir.glob(log_file_path).first
          next unless log_file

          logs[service_name] = redact_home(Support::Rake::TaskLogger.new(log_file).tail)
        end
      end

      def log_file_name(service_name)
        Time.now.strftime("rake-%Y-%m-%d_*/#{service_name}.log")
      end

      def git_repositories
        REPOSITORY_NAMES.each_with_object({}) do |repo_name, repositories|
          repositories[repo_name] = {
            git_status: git_status(repo_name),
            git_head: git_head(repo_name)
          }
        end
      end

      def date_time
        Time.now.strftime('%d/%m/%Y %H:%M:%S %Z')
      end

      def git_status(repo_name)
        command = repo_name == 'kdk' ? 'git status' : "cd #{repo_name} && git status"
        shellout(command)
      end

      def git_head(repo_name)
        command = repo_name == 'kdk' ? 'git show HEAD' : "cd #{repo_name} && git show HEAD"
        shellout(command)[/.*/]
      end

      def shellout(cmd, **args)
        debug_info.shellout(cmd, **args)
      end

      def redact_home(message)
        message.gsub(Dir.home, ConfigRedactor::HOME_REDACT_WITH)
      end

      def copy_clipboard(content)
        (command = find_command(COPY_COMMANDS)) ||
          abort('Could not automatically copy message to clipboard. Please copy the output manually.')

        IO.popen(::Shellwords.split(command), 'w') do |pipe|
          pipe.print(content)
        end
      end

      def open_browser
        (command = find_command(OPEN_COMMANDS)) ||
          abort('Could not automatically open browser. Please open the URL manually.')

        url = URI(NEW_ISSUE_URL)
        url.query = query

        system(*Shellwords.split(command), url)
      end

      def query
        URI.encode_www_form(
          'issue[issue_type]': :incident,
          'issue[confidential]': true,
          'issue[title]': "KDK Troubleshooting Report #{report_id}: ENTER A TITLE FOR YOUR REPORT",
          'issue[description]': description
        )
      end

      def description
        <<~MARKDOWN
          #{LABELING}

          <!-- Please paste the report from your clipboard below here. -->
        MARKDOWN
      end

      def find_command(list)
        list.find { |command| Utils.find_executable(command.split.first) }
      end

      private

      attr_reader :report_id, :debug_info
    end
  end
end
