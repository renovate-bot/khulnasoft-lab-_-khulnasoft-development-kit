# frozen_string_literal: true

require 'etc'
require 'openssl'

autoload :KhulnasoftSDK, 'khulnasoft-sdk'
autoload :Sentry, 'sentry-ruby'
autoload :SnowplowTracker, 'snowplow-tracker'

module KDK
  module Telemetry
    ANALYTICS_APP_ID = 'e2e967c0-785f-40ae-9b45-5a05f729a27f'
    ANALYTICS_BASE_URL = 'https://collector.prod-1.gl-product-analytics.com'
    # Track events emitted on CI in https://khulnasoft.com/khulnasoft-org/quality/tooling/kdk-playground/
    CI_ANALYTICS_APP_ID = '6a31192c-6567-40a3-9413-923abc790f05'

    SENTRY_DSN = 'https://4e771163209528e15a6a66a6e674ddc3@new-sentry.khulnasoft.net/38'
    PROMPT_TEXT = <<~TEXT.chomp
      To improve KDK, KhulnaSoft would like to collect basic error and usage information, including your platform and architecture.

      Would you like to send telemetry anonymously to KhulnaSoft? [y/n]
    TEXT
    FLUSH_TIMEOUT_SECONDS = 3

    def self.with_telemetry(command)
      return yield unless telemetry_enabled?

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      err = nil
      begin
        result = yield
      rescue StandardError => e
        err = e
        result = false
      ensure
        duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      end

      send_telemetry(result, command, duration: duration)

      result
    ensure
      raise err if err
    end

    def self.send_telemetry(success, command, duration:)
      # This is tightly coupled to KDK commands and returns false when the system call exits with a non-zero status.
      status = success ? 'Finish' : 'Failed'

      client.identify(KDK.config.telemetry.username)
      client.track("#{status} #{command} #{ARGV}", payload.merge(duration: duration))
    end

    def self.flush_events(async: false)
      Timeout.timeout(FLUSH_TIMEOUT_SECONDS) do
        client.flush_events(async: async)
      end
    rescue Timeout::Error
      KDK::Output.warn(
        "Could not flush telemetry events within #{FLUSH_TIMEOUT_SECONDS} seconds. Is #{telemetry_host} blocked or unreachable?"
      )
    end

    def self.environment
      KDK.config.telemetry.environment
    end

    def self.version_manager
      return 'asdf' unless KDK.config.asdf.opt_out?
      return 'mise' if KDK.config.mise.enabled?

      'none'
    end

    def self.session_id
      @session_id ||= SecureRandom.uuid
    end

    def self.client
      return @client if @client

      default_app_id = ENV['CI'] ? CI_ANALYTICS_APP_ID : ANALYTICS_APP_ID

      app_id = ENV.fetch('KHULNASOFT_SDK_APP_ID', default_app_id)
      host = telemetry_host

      SnowplowTracker::LOGGER.level = Logger::WARN
      SnowplowTracker::LOGGER.extend LoggerWithoutBacktrace

      at_exit do
        # Flush all pending events synchronously before exit.
        KDK::Telemetry.flush_events
      end

      @client = KhulnasoftSDK::Client.new(app_id: app_id, host: host, buffer_size: 10)
    end

    def self.telemetry_host
      ENV.fetch('KHULNASOFT_SDK_HOST', ANALYTICS_BASE_URL)
    end

    def self.init_sentry
      return if Sentry.configuration

      Sentry.init do |config|
        config.dsn = SENTRY_DSN
        config.breadcrumbs_logger = [:sentry_logger]
        config.traces_sample_rate = 1.0
        config.logger.level = Logger::WARN

        # Pseudonymize server name using checksum for username and hostname
        config.server_name = OpenSSL::Digest::SHA256.hexdigest([KDK.config.telemetry.username, config.server_name].join(':'))[0, 16]

        config.before_send = lambda do |event, hint|
          exception = hint[:exception]

          # Workaround for using fingerprint to make certain errors distinct.
          # See https://khulnasoft.com/khulnasoft-org/opstrace/opstrace/-/issues/2842#note_1927103517
          event.transaction = exception.message if exception.is_a?(Shellout::ShelloutBaseError)

          event
        end
      end

      Sentry.set_user(username: KDK.config.telemetry.username)
    end

    def self.capture_exception(message, attachment: nil)
      return unless telemetry_enabled?

      if message.is_a?(Exception)
        exception = message.dup
      else
        exception = StandardError.new(message)
        exception.set_backtrace(caller)
      end

      # Drop the caller KDK::Telemetry.capture_exception to make errors distinct.
      exception.set_backtrace(exception.backtrace.drop(1)) if exception.backtrace

      init_sentry

      Sentry.configure_scope do |scope|
        scope.set_context('kdk', payload)
      end

      Sentry.add_attachment(**attachment) if attachment
      Sentry.capture_exception(exception)
    end

    def self.telemetry_enabled?
      return false if ENV['KDK_TELEMETRY'] == '0'

      KDK.config.telemetry.enabled
    end

    def self.payload
      {
        session_id: session_id,
        environment: environment,
        platform: KDK::Machine.platform,
        architecture: KDK::Machine.architecture,
        version_manager: version_manager,
        team_member: team_member?,
        enabled_services: enabled_services,
        cpu_count: Etc.nprocessors
      }
    end

    # Returns true if the user has configured a @khulnasoft.com email for git.
    #
    # This should only be used for telemetry and NEVER for authentication.
    def self.team_member?
      return @team_member if defined?(@team_member)

      @team_member = Shellout.new(%w[git config --get user.email])
              .run.include?('@khulnasoft.com')

      return @team_member if @team_member

      @team_member =
        if KDK::Machine.macos?
          # See https://handbook.khulnasoft.com/handbook/security/corporate/systems/jamf/setup/
          Shellout
            .new(%w[profiles status -type enrollment])
            .execute(display_output: false, display_error: false)
            .read_stdout.include?('khulnasoft.jamfcloud.com')
        elsif KDK::Machine.linux?
          # KhulnaSoft hostname standard
          hostname_match = -> { /\A\S+--\d+-\w+\z$/.match?(Etc.uname[:nodename]) }
          file_contains = ->(file, regexp) { File.exist?(file) && File.foreach(file).any?(regexp) }

          hostname_match.call ||
            !!file_contains.call(Pathname(Dir.home).join('.config/zoomus.conf'), /khulnasoft\.zoom\.us/)
        else
          false
        end
    end

    def self.enabled_services
      KDK::ToolVersionsUpdater.enabled_services
    end

    def self.update_settings(answer)
      enabled = answer == 'y'

      if enabled != KDK.config.telemetry.enabled
        KDK.config.bury!('telemetry.enabled', enabled)
        changes_made = true
      end

      if enabled
        username = KDK.config.telemetry.username
        anonymized = /\A\h{32}\z/.match?(username)

        unless anonymized
          KDK.config.bury!('telemetry.username', SecureRandom.hex)
          KDK::Output.info('Telemetry username has been anonymized.')
          changes_made = true
        end
      end

      KDK.config.save_yaml! if changes_made
    end

    # To reduce noise skip long backtraces for all system call errors like "connection refused".
    module LoggerWithoutBacktrace
      def warn(message)
        message.set_backtrace([]) if message.is_a?(SystemCallError)

        super
      end
    end
  end
end
