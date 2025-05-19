# frozen_string_literal: true

module KDK
  # KDK Commands
  module Command
    # This is a list of existing supported commands and their associated
    # implementation class
    COMMANDS = {
      'cells' => -> { KDK::Command::Cells },
      'cleanup' => -> { KDK::Command::Cleanup },
      'clickhouse' => -> { KDK::Command::Clickhouse },
      'config' => -> { KDK::Command::Config },
      'console' => -> { KDK::Command::Console },
      'bao' => -> { KDK::Command::Bao },
      'debug-info' => -> { KDK::Command::DebugInfo },
      'diff-config' => -> { KDK::Command::DiffConfig },
      'doctor' => -> { KDK::Command::Doctor },
      'env' => -> { KDK::Command::Env },
      'install' => -> { KDK::Command::Install },
      'kill' => -> { KDK::Command::Kill },
      'help' => -> { KDK::Command::Help },
      '-help' => -> { KDK::Command::Help },
      '--help' => -> { KDK::Command::Help },
      '-h' => -> { KDK::Command::Help },
      nil => -> { KDK::Command::Help },
      'measure' => -> { KDK::Command::MeasureUrl },
      'measure-workflow' => -> { KDK::Command::MeasureWorkflow },
      'open' => -> { KDK::Command::Open },
      'telemetry' => -> { KDK::Command::Telemetry },
      'psql' => -> { KDK::Command::Psql },
      'psql-geo' => -> { KDK::Command::PsqlGeo },
      'pristine' => -> { KDK::Command::Pristine },
      'rails' => -> { KDK::Command::Rails },
      'reconfigure' => -> { KDK::Command::Reconfigure },
      'redis-cli' => -> { KDK::Command::RedisCli },
      'report' => -> { KDK::Command::Report },
      'reset-data' => -> { KDK::Command::ResetData },
      'reset-praefect-data' => -> { KDK::Command::ResetPraefectData },
      'reset-registry-data' => -> { KDK::Command::ResetRegistryData },
      'import-registry-data' => -> { KDK::Command::ImportRegistryData },
      'restart' => -> { KDK::Command::Restart },
      'start' => -> { KDK::Command::Start },
      'status' => -> { KDK::Command::Status },
      'stop' => -> { KDK::Command::Stop },
      'switch' => -> { KDK::Command::Switch },
      'tail' => -> { KDK::Command::Tail },
      'truncate-legacy-tables' => -> { KDK::Command::TruncateLegacyTables },
      'update' => -> { KDK::Command::Update },
      'version' => -> { KDK::Command::Version },
      '-version' => -> { KDK::Command::Version },
      '--version' => -> { KDK::Command::Version }
    }.freeze

    # Entry point for gem/bin/kdk.
    #
    # It must return true/false or an exit code.
    def self.run(argv)
      name = argv.shift
      command = ::KDK::Command::COMMANDS[name]

      if command
        klass = command.call

        check_gem_version!
        validate_config! if klass.validate_config?
        result = KDK::Telemetry.with_telemetry(name) { klass.new.run(argv) }

        exit result
      else
        suggestions = DidYouMean::SpellChecker.new(dictionary: ::KDK::Command::COMMANDS.keys).correct(name)
        message = ["#{name} is not a KDK command"]

        if suggestions.any?
          message << ', did you mean - '
          message << suggestions.map { |suggestion| "'kdk #{suggestion}'" }.join(' or ')
          message << '?'
        else
          message << '.'
        end

        KDK::Output.warn message.join
        KDK::Output.puts

        KDK::Output.info "See 'kdk help' for more detail."
        false
      end
    end

    def self.validate_config!
      KDK.config.validate!
      KDK::Services.enabled.each(&:validate!)
      nil
    rescue StandardError => e
      KDK::Output.error("Your KDK configuration is invalid.\n\n", e)
      KDK::Output.puts(e.message, stderr: true)
      abort('')
    end

    def self.check_gem_version!
      return if Gem::Version.new(KDK::GEM_VERSION) >= Gem::Version.new(KDK::REQUIRED_GEM_VERSION)

      KDK::Output.warn("You are running an old version of the `khulnasoft-development-kit` gem (#{KDK::GEM_VERSION})")
      KDK::Output.info("Please update your `khulnasoft-development-kit` to version #{KDK::REQUIRED_GEM_VERSION}:")
      KDK::Output.info("gem install khulnasoft-development-kit -v #{KDK::REQUIRED_GEM_VERSION}")
      KDK::Output.puts
    end
  end
end
