# frozen_string_literal: true

module KDK
  module Diagnostic
    class Postgresql < Base
      TITLE = 'PostgreSQL'

      def success?
        @success ||= data_dir_version && versions_ok? && can_create_postgres_socket? && valid_ldflags?
      end

      def detail
        return if success?

        output = []
        output << version_problem_message unless versions_ok?
        output << cant_create_socket_message unless can_create_postgres_socket?
        output << invalid_ldflags_message unless valid_ldflags?

        output.join("\n#{diagnostic_detail_break}\n")
      end

      private

      def version_problem_message
        cmd_version = psql_version || 'unknown'
        data_version = data_dir_version || 'unknown'

        <<~MESSAGE
          `psql` is version #{cmd_version}, but your PostgreSQL data dir is using version #{data_version}.

          Check that your PATH is pointing to the right PostgreSQL version, or see the PostgreSQL upgrade guide:
          https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/master/doc/howto/postgresql.md#upgrade-postgresql
        MESSAGE
      end

      def can_create_postgres_socket?
        return true if KDK::Postgresql.new.use_tcp?

        # use a temporary file the same character length as 'postgresql/.s.PGSQL.port'
        # port max is 65535, so assume 5 characters for the port number
        # socket_path = config.kdk_root.join('postgresql_.s.PGSQL.XXXXX')
        socket_path = config.kdk_root.join('postgresql_.s.PGSQL.XXXXX').to_s

        can_create_socket?(socket_path)
      end

      def cant_create_socket_message
        <<~MESSAGE
          KDK directory's character length (#{config.kdk_root.to_s.length}) is too long to support the creation
          of a UNIX socket for Postgres:

            #{config.kdk_root}

          Try using a shorter directory path for KDK or use TCP for Postgres.
        MESSAGE
      end

      def versions_ok?
        psql_command.success? && psql_version && data_dir_version && versions_match?
      end

      def versions_match?
        if psql_version >= 10
          data_dir_version.to_i == psql_version.to_i
        else
          # Avoid floating point comparison issues by using rationals
          data_dir_version.to_r.round(2) == psql_version.to_r.round(2)
        end
      end

      def psql_version
        return unless psql_command.success?

        match = psql_command.read_stdout&.match(/psql \(PostgreSQL\) (.*)/)

        return unless match

        match[1].to_f
      end

      def psql_command
        @psql_command ||= begin
          psql = config.postgresql.bin_dir.join('psql')
          Shellout.new(%W[#{psql} --version]).execute(display_output: false, display_error: false)
        end
      end

      def data_dir_version
        return unless File.exist?(data_dir_version_filename)

        @data_dir_version ||= File.read(data_dir_version_filename).to_f
      end

      def data_dir_version_filename
        @data_dir_version_filename ||= File.join(config.postgresql.data_dir, 'PG_VERSION')
      end

      def invalid_ldflags_message
        <<~MESSAGE
          #{@pgconfig_error}

          This may indicate a potential issue with the PostgreSQL installation, and we recommend reinstalling PostgreSQL.

          You can try running the following to reinstall PostgreSQL:

          #{reinstall_message}
        MESSAGE
      end

      def reinstall_message
        manager = asdf? ? 'asdf' : 'mise'

        "#{manager} uninstall postgres #{psql_version} && #{manager} install postgres #{psql_version}"
      end

      def asdf?
        KDK::Dependencies.asdf_available?
      end

      def valid_ldflags?
        return @valid_ldflags if defined?(@valid_ldflags)

        @valid_ldflags = pg_config_valid?
      end

      def pg_config_valid?
        return true unless pgvector_enabled?

        unless pg_config_ldflags.include?('-isysroot')
          @pgconfig_error = 'The `-isysroot` value not present in `pg_config --ldflags`.'
          return false
        end

        isysroot_path = pg_config_ldflags[/-isysroot\s(\S+)/, 1]
        unless Dir.exist?(isysroot_path)
          @pgconfig_error = "The `-isysroot` path #{isysroot_path} does not exist."
          return false
        end

        if macos? && !isysroot_path_matches_sdk?(isysroot_path, xcrun_sdk_path)
          @pgconfig_error = "The `pg_config --ldflags` shows #{isysroot_path}, but `xcrun --show-sdk-path` shows #{xcrun_sdk_path}."
          return false
        end

        true
      end

      def pgvector_enabled?
        config.pgvector.enabled
      end

      def isysroot_path_matches_sdk?(isysroot_path, xcrun_sdk_path)
        File.realpath(isysroot_path) == File.realpath(xcrun_sdk_path)
      end

      def macos?
        RUBY_PLATFORM.include?('darwin')
      end

      def pg_config_ldflags
        @pg_config_ldflags ||= Shellout.new('pg_config --ldflags').execute(display_output: false).read_stdout
      end

      def xcrun_sdk_path
        @xcrun_sdk_path ||= Shellout.new('xcrun --show-sdk-path').execute(display_output: false).read_stdout.to_s
      end

      def config
        KDK.config
      end
    end
  end
end
