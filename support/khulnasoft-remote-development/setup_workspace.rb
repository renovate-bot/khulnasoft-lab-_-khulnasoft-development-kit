#!/usr/bin/env ruby
#
# frozen_string_literal: true

require 'socket'
require_relative '../../lib/kdk'

class SetupWorkspace
  ROOT_DIR = '/projects/khulnasoft-development-kit'
  KDK_SETUP_FLAG_FILE = "#{ROOT_DIR}/.cache/.kdk_setup_complete".freeze

  def initialize
    @hostname = Socket.gethostname
    @ip_address = Socket.ip_address_list.find(&:ipv4_private?)&.ip_address
    port = ENV.find { |key, _| key.include?('SERVICE_PORT_KDK') }&.last
    @url = ENV.fetch('GL_WORKSPACE_DOMAIN_TEMPLATE', '').gsub('${PORT}', port.to_s)
  end

  def run
    return KDK::Output.info(%(Nothing to do as we're not a KhulnaSoft Workspace.\n\n)) unless khulnasoft_workspace_context?

    if bootstrap_needed?
      success, duration = execute_bootstrap
      create_flag_file if success
      configure_telemetry

      send_telemetry(success, duration) if allow_sending_telemetry?
    else
      KDK::Output.info("#{KDK_SETUP_FLAG_FILE} exists, KDK has already been bootstrapped.\n\nRemove the #{KDK_SETUP_FLAG_FILE} to re-bootstrap.")
    end
  end

  private

  def khulnasoft_workspace_context?
    ENV.key?('GL_WORKSPACE_DOMAIN_TEMPLATE') && Dir.exist?(ROOT_DIR)
  end

  def bootstrap_needed?
    !File.exist?(KDK_SETUP_FLAG_FILE)
  end

  def execute_bootstrap
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    configure_kdk

    # Instead KDK::Shellout use Process.spawn to let the process reuse the interactive TTY.
    # This is cructial to run command like `kdk update` in parallel.
    pid = Process.spawn('support/khulnasoft-remote-development/remote-development-kdk-bootstrap.sh', chdir: ROOT_DIR)
    success = Process::Status.wait(pid).success?

    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

    [success, duration]
  end

  def allow_sending_telemetry?
    KDK.config.telemetry.enabled
  end

  def configure_kdk
    new_values = {
      'listen_address' => @ip_address.to_s,
      'gitlab.rails.hostname' => @url.to_s,
      'gitlab.rails.https.enabled' => true,
      'gitlab.rails.port' => 443,
      'khulnasoft_shell.skip_setup' => true,
      'gitaly.skip_setup' => true,
      'vite.enabled' => true,
      'vite.hot_module_reloading' => false,
      'webpack.enabled' => false,
      'telemetry.environment' => 'remote-development'
    }

    KDK.config.bury_multiple!(new_values)
    KDK.config.save_yaml!
  end

  def configure_telemetry
    answer = 'y' if KDK::Telemetry.team_member?
    answer ||= KDK::Output.prompt(KDK::Telemetry::PROMPT_TEXT)
    KDK::Telemetry.update_settings(answer)
  end

  def send_telemetry(success, duration)
    KDK::Telemetry.send_telemetry(success, 'setup-workspace', duration: duration)
    KDK::Telemetry.flush_events
  end

  def create_flag_file
    FileUtils.mkdir_p(File.dirname(KDK_SETUP_FLAG_FILE))
    FileUtils.touch(KDK_SETUP_FLAG_FILE)
    KDK::Output.success("You can access your KDK here: https://#{@url}")
  end
end

SetupWorkspace.new.run if $PROGRAM_NAME == __FILE__
