# frozen_string_literal: true

module KDK
  module Dependencies
    class Checker
      EXPECTED_YARN_VERSION = '1.22.5'
      EXPECTED_NODEJS_VERSION = '20.12.2'
      EXPECTED_POSTGRESQL_VERSION = KDK::Postgresql.target_version.to_s
      EXPECTED_REDIS_VERSION = KDK::Redis.target_version.to_s

      attr_reader :error_messages

      def self.parse_version(string, prefix: '')
        string[/#{prefix}((\d+\.\d+)(\.\d+)*)/, 1]
      end

      def initialize(preflight: false)
        @preflight = preflight
        @error_messages = []
      end

      def check_all
        check_ruby_version
        check_nodejs_version
        check_yarn_version
        check_postgresql_version
        check_redis_version

        check_brew_dependencies_installed
        check_exiftool_installed
        check_git_installed
        check_graphicsmagick_installed
        check_meson_installed
        check_minio_installed
        check_ninja_installed
        check_runit_installed
        check_nginx_installed

        check_ruby_gems_ok if @preflight
      end

      def check_binary(binary, name: binary)
        Utils.find_executable(binary).tap do |result|
          @error_messages << missing_dependency(name) unless result
        end
      end

      def check_ruby_version
        return unless check_binary('ruby')

        cmd = 'ruby --version'
        # .tool-versions may have changed during a `kdk update`, so we
        # should execute ruby using asdf to avoid a stale PATH.
        cmd = "asdf exec #{cmd}" if KDK::Dependencies.asdf_available?

        raw_version_match = Shellout.new(cmd).try_run.match(/\Aruby (.+)p\d+ \(.+\z/)
        return unless raw_version_match

        actual = Gem::Version.new(raw_version_match[1])
        expected = Gem::Version.new(KhulnasoftVersions.new.ruby_version)

        @error_messages << require_minimum_version('Ruby', actual, expected) if actual < expected
      end

      def check_nodejs_version
        return unless check_binary('node')

        current_version = Checker.parse_version(`node --version`, prefix: 'v')

        raise MissingDependency unless current_version

        actual = Gem::Version.new(current_version)
        expected = Gem::Version.new(EXPECTED_NODEJS_VERSION)

        @error_messages << require_minimum_version('Node.js', actual, expected) if actual < expected
      rescue Errno::ENOENT, MissingDependency
        @error_messages << missing_dependency('Node.js', minimum_version: EXPECTED_NODEJS_VERSION)
      end

      def check_yarn_version
        return unless check_binary('yarn')

        current_version = Checker.parse_version(`yarn --version`)
        expected = Gem::Version.new(EXPECTED_YARN_VERSION)

        raise MissingDependency unless current_version

        actual = Gem::Version.new(current_version)
        @error_messages << require_minimum_version('Yarn', actual, expected) if actual < expected
      rescue Errno::ENOENT, MissingDependency
        @error_messages << missing_dependency('Yarn', minimum_version: expected)
      end

      def check_postgresql_version
        psql = config.postgresql.bin_dir.join('psql')

        return unless check_binary(psql)

        current_version = Checker.parse_version(`#{psql} --version`, prefix: 'psql \(PostgreSQL\) ')
        expected = Gem::Version.new(EXPECTED_POSTGRESQL_VERSION)

        raise MissingDependency unless current_version

        actual = Gem::Version.new(current_version)
        @error_messages << require_minimum_version('PostgreSQL', actual, expected) if actual < expected
      rescue Errno::ENOENT, MissingDependency
        @error_messages << missing_dependency('PostgreSQL', minimum_version: expected)
      end

      def check_redis_version
        return unless check_binary('redis-server')

        current_version = Checker.parse_version(`redis-server --version`, prefix: 'Redis server v=')
        expected = Gem::Version.new(EXPECTED_REDIS_VERSION)

        raise MissingDependency unless current_version

        actual = Gem::Version.new(current_version)
        @error_messages << require_minimum_version('redis', actual, expected) if actual < expected
      rescue Errno::ENOENT, MissingDependency
        @error_messages << missing_dependency('redis', minimum_version: expected)
      end

      def check_brew_dependencies_installed
        cmd = 'brew bundle check -v --no-upgrade'
        result = Shellout.new(cmd).try_run

        missing_dependencies = result.scan(/(Cask|Formula) (.*?) needs to be installed./).map(&:last) unless result.include?("The Brewfile's dependencies are satisfied.")

        return if missing_dependencies.nil? || missing_dependencies.empty? || ENV['OSTYPE'] != 'darwin'

        msg = <<~MESSAGE
          The following Brewfile's dependencies are missing or outdated:

          - #{missing_dependencies.join("\n- ")}

          To install these dependencies, run the following command:

            (cd #{config.kdk_root} && brew bundle)
        MESSAGE
        @error_messages << msg
      end

      def check_exiftool_installed
        return if system('exiftool -ver >/dev/null 2>&1')

        msg = "You may need to run 'brew reinstall exiftool'." if KDK::Machine.macos?
        @error_messages << missing_dependency('Exiftool', more_detail: msg)
      end

      def check_git_installed
        check_binary('git')
      end

      def check_graphicsmagick_installed
        @error_messages << missing_dependency('GraphicsMagick') unless system('gm version >/dev/null 2>&1')
      end

      def check_meson_installed
        check_binary('meson')
      end

      def check_minio_installed
        return unless config.object_store.enabled?

        @error_messages << missing_dependency('MinIO') unless system('minio --help >/dev/null 2>&1')
      end

      def check_ninja_installed
        check_binary('ninja')
      end

      def check_runit_installed
        check_binary('runsvdir', name: 'Runit')
      end

      def check_nginx_installed
        return unless config.nginx?

        check_binary(config.nginx.bin, name: 'nginx')
      end

      def require_minimum_version(dependency, actual, expected)
        "ERROR: #{dependency} version #{actual} detected, please install #{dependency} version #{expected} or higher."
      end

      def missing_dependency(dependency, minimum_version: nil, more_detail: nil)
        message = "ERROR: #{dependency} is not installed or not available in your PATH."
        message += " #{minimum_version} or higher is required." unless minimum_version.nil?
        message += " #{more_detail}" unless more_detail.nil?

        message
      end

      def check_ruby_gems_ok
        checker = KDK::Diagnostic::RubyGems.new(allow_gem_not_installed: true)
        return if checker.success?

        @error_messages << "ERROR: #{checker.detail}"
        @error_messages << nil
      end

      private

      def config
        KDK.config
      end
    end
  end
end
