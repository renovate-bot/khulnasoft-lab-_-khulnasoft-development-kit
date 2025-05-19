# frozen_string_literal: true

require 'cgi'
require 'etc'
require 'uri'
require 'pathname'

module KDK
  class Config < ConfigSettings
    KDK_ROOT = Pathname.new(__dir__).parent.parent
    FILE = File.join(KDK_ROOT, 'kdk.yml')

    string(:__platform) { KDK::Machine.platform }

    bool(:__supports_precompiled_binaries) { KDK::PackageHelper.supported_os_arch?(KDK::Machine.package_platform) }

    path(:__brew_prefix_path) do
      if KDK::Machine.macos?
        if File.exist?('/opt/homebrew/bin/brew')
          '/opt/homebrew'
        elsif File.exist?('/usr/local/bin/brew')
          '/usr/local'
        else
          ''
        end
      else
        ''
      end
    end

    path(:__openssl_bin_path) do
      if config.__brew_prefix_path.to_s.empty?
        Pathname.new(find_executable!('openssl'))
      else
        config.__brew_prefix_path.join('opt', 'openssl', 'bin', 'openssl')
      end
    end

    def kdk_root
      self.class::KDK_ROOT
    end

    path(:__data_dir) { kdk_root.join('data') }
    path(:__cache_dir) { kdk_root.join('.cache') }
    integer(:restrict_cpu_count) { Etc.nprocessors }

    hash_setting(:env, merge: true) do
      {
        'RAILS_ENV' => 'development',
        'CUSTOMER_PORTAL_URL' => config.license.customer_portal_url,
        'KHULNASOFT_LICENSE_MODE' => config.license.license_mode
      }.tap do |env|
        if config.tracer.jaeger?
          env.merge!(
            'KHULNASOFT_TRACING' => config.tracer.jaeger.__tracer_url,
            'KHULNASOFT_TRACING_URL' => config.tracer.jaeger.__search_url
          )
        end
      end
    end

    settings :common do
      string(:ca_path) { '' }
    end

    settings :khulnasoft_ai_gateway do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      port(:port, 'khulnasoft_ai_gateway')
      string(:version) { 'main' }
      string(:__listen) { "http://#{config.hostname}:#{config.khulnasoft_ai_gateway.port}" }
      string(:__service_command) { 'support/exec-cd gitlab-ai-gateway poetry run ai_gateway' }
    end

    settings :khulnasoft_http_router do
      bool(:enabled) { true }
      bool(:auto_update) { true }
      bool(:use_distinct_port) { false }
      string(:khulnasoft_rules_config) { 'session_prefix' }
      port(:port, 'khulnasoft_http_router')
      string(:__version) { ConfigHelper.version_from(config, 'KHULNASOFT_HTTP_ROUTER_VERSION') }
    end

    settings :khulnasoft_observability_backend do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :siphon do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      array(:tables) { %w[namespaces projects] }
    end

    settings :nats do
      bool(:enabled) { config.siphon? }
      bool(:auto_update) { true }
    end

    settings :khulnasoft_topology_service do
      bool(:enabled) { true }
      bool(:auto_update) { true }
      port(:grpc_port, 'khulnasoft_topology_service_grpc')
      port(:rest_port, 'khulnasoft_topology_service_rest')
      path(:certificate_file) { config.kdk_root.join("khulnasoft-topology-service/tmp/certs/server-cert.pem") }
      path(:key_file) { config.kdk_root.join("khulnasoft-topology-service/tmp/certs/server-key.pem") }
      path(:client_certificate_file) { config.kdk_root.join("khulnasoft-topology-service/tmp/certs/client-cert.pem") }
      string(:__version) { ConfigHelper.version_from(config, 'KHULNASOFT_TOPOLOGY_SERVICE_VERSION') }
    end

    settings :telemetry do
      string(:username) { '' }
      bool(:enabled) { false }
      string(:environment) { 'native' }
    end

    settings :repositories do
      string(:charts_gitlab) { 'https://gitlab.com/gitlab-org/charts/gitlab.git' }
      string(:docs_khulnasoft_com) { 'https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com.git' }
      string(:gitaly) { 'https://gitlab.com/gitlab-org/gitaly.git' }
      string(:gitlab) { 'https://github.com/khulnasoft-lab/khulnasoft.git' }
      string(:khulnasoft_ai_gateway) { 'https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist.git' }
      string(:khulnasoft_http_router) { 'https://gitlab.com/gitlab-org/cells/http-router.git' }
      string(:khulnasoft_elasticsearch_indexer) { 'https://github.com/khulnasoft-lab/khulnasoft-elasticsearch-indexer.git' }
      string(:khulnasoft_k8s_agent) { 'https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent.git' }
      string(:khulnasoft_operator) { 'https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git' }
      string(:khulnasoft_pages) { 'https://github.com/khulnasoft-lab/khulnasoft-pages.git' }
      string(:khulnasoft_shell) { 'https://github.com/khulnasoft-lab/khulnasoft-shell.git' }
      string(:khulnasoft_topology_service) { 'https://gitlab.com/gitlab-org/cells/topology-service.git' }
      string(:khulnasoft_runner) { 'https://github.com/khulnasoft-lab/khulnasoft-runner.git' }
      string(:khulnasoft_ui) { 'https://github.com/khulnasoft-lab/khulnasoft-ui.git' }
      string(:khulnasoft_zoekt_indexer) { 'https://gitlab.com/gitlab-org/khulnasoft-zoekt-indexer.git' }
      string(:omnibus_gitlab) { 'https://gitlab.com/gitlab-org/omnibus-gitlab.git' }
      string(:openbao_internal) { 'https://gitlab.com/gitlab-org/govern/secrets-management/openbao-internal.git' }
      string(:registry) { 'https://gitlab.com/gitlab-org/container-registry.git' }
      string(:khulnasoft_observability_backend) { 'git@gitlab.com:gitlab-org/opstrace/opstrace.git' }
      string(:siphon) { 'https://gitlab.com/gitlab-org/analytics-section/siphon.git' }
      string(:duo_workflow_executor) { 'https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor.git' }
    end

    settings :dev do
      path(:__go_path) { KDK.root.join('dev') }
      path(:__bins) { config.dev.__go_path.join('bin') }
      path(:__go_binary) { find_executable!('go') }
      bool(:__go_binary_available?) do
        !config.dev.__go_binary.nil?
      rescue TypeError
        false
      end

      settings(:checkmake) do
        string(:version) { '8915bd4' }
        path(:__binary) { config.dev.__bins.join('checkmake') }
        path(:__versioned_binary) { config.dev.__bins.join("checkmake_#{config.dev.checkmake.version}") }
      end
    end

    array(:git_repositories) do
      # This list in not exhaustive yet, as some git repositories are based on
      # a fake GOPATH inside a projects sub directory
      ["/", "gitlab"].map { |d| File.join(kdk_root, d) }.select { |d| Dir.exist?(d) }
    end

    settings :kdk do
      bool(:ask_to_restart_after_update) { true }
      bool(:debug) { false }
      bool(:__debug) { ENV.fetch('KDK_DEBUG', 'false') == 'true' || config.kdk.debug? }
      integer(:runit_wait_secs) { 20 }
      bool(:auto_reconfigure) { true }
      bool(:auto_rebase_projects) { false }
      bool(:use_bash_shim) { false }
      bool(:overwrite_changes) { false }
      bool(:system_packages_opt_out) { false }
      bool(:rubygems_update_opt_out) { false }
      bool(:preflight_checks_opt_out) { false }
      array(:protected_config_files) { [] }
      settings :start_hooks do
        array(:before) { [] }
        array(:after) { [] }
      end
      settings :stop_hooks do
        array(:before) { [] }
        array(:after) { [] }
      end
      settings :update_hooks do
        array(:before, merge: true) { ['support/exec-cd gitlab bin/spring stop || true'] }
        array(:after) { [] }
      end
    end

    path(:repositories_root) { config.kdk_root.join('repositories') }
    path(:repository_storages) { config.kdk_root.join('repository_storages') }

    string(:listen_address) { '127.0.0.1' }
    string(:hostname) { config.listen_address }
    port(:port, 'kdk')
    integer(:port_offset) { 0 }

    settings :https do
      bool(:enabled) { false }
    end

    string(:relative_url_root) { '' }

    anything :__uri do
      # Only include the port if it's 'non standard'
      klass = config.https? ? URI::HTTPS : URI::HTTP
      relative_url_root = config.relative_url_root.gsub(%r{/+$}, '')

      klass.build(host: config.hostname, port: config.port, path: relative_url_root)
    end

    string(:username) { Etc.getpwuid.name }
    string(:__whoami) { Etc.getpwuid.name }

    settings :license do
      string(:customer_portal_url) { 'https://customers.staging.gitlab.com' }
      string(:license_mode) { 'test' }
    end

    settings :load_balancing do
      bool(:enabled) { false }
      settings :discover do
        bool(:enabled) { false }
      end
    end

    settings :vite do
      bool(:enabled) { false }

      settings :https do
        bool(:enabled) { config.https.enabled }
      end

      port(:port, 'vite')
      bool(:hot_module_reloading) { true }
      integer(:vue_version) { 2 }
    end

    settings :webpack do
      bool(:enabled) { true }
      string(:host) { config.gitlab.rails.hostname }
      port(:port, 'webpack')
      string(:public_address) { "" }
      bool(:static) { false }
      bool(:vendor_dll) { false }
      bool(:incremental) { true }
      integer(:incremental_ttl) { 30 }
      bool(:sourcemaps) { true }
      bool(:live_reload) { true }
      array(:allowed_hosts) { config.gitlab.rails.allowed_hosts }
      integer(:vue_version) { 2 }

      bool(:__set_vue_version) do
        config.webpack.vue_version == 3
      end
      string(:__dev_server_public) do
        if !config.webpack.live_reload
          ""
        elsif !config.webpack.public_address.empty?
          config.webpack.public_address
        elsif config.nginx?
          # webpack behind nginx
          if config.https?
            "wss://#{config.nginx.__listen_address}/_hmr/"
          else
            "ws://#{config.nginx.__listen_address}/_hmr/"
          end
        else
          ""
        end
      end
    end

    settings :action_cable do
      integer(:worker_pool_size) { 4 }
    end

    settings :workhorse do
      bool(:enabled) { true }
      bool(:skip_compile) { config.__supports_precompiled_binaries }
      bool(:skip_setup) { false }
      port(:configured_port, 'workhorse')
      integer(:ci_long_polling_seconds) { 0 }

      settings :__listen_settings do
        string(:__type) do
          if config.gitlab.rails.address.empty?
            'authSocket'
          else
            'authBackend'
          end
        end

        string(:__address) do
          config.gitlab.rails.__workhorse_url
        end
      end

      string(:__active_host) { config.hostname }

      integer :__active_port do
        if config.khulnasoft_http_router? || config.nginx?
          config.workhorse.configured_port
        else
          # Workhorse is the user-facing entry point whenever neither nginx nor
          # AutoDevOps is used, so in that situation use the configured KDK port.
          config.port
        end
      end

      string :__listen_address do
        "#{config.workhorse.__active_host}:#{config.workhorse.__active_port}"
      end

      string :__command_line_listen_addr do
        if config.https?
          "#{config.hostname}:0"
        else
          config.workhorse.__listen_address
        end
      end
    end

    settings :khulnasoft_shell do
      bool(:skip_compile) { config.__supports_precompiled_binaries }
      bool(:skip_setup) { false }
      bool(:auto_update) { true }
      path(:dir) { config.kdk_root.join('gitlab-shell') }
      settings :lfs do
        # https://gitlab.com/groups/gitlab-org/-/epics/11872
        bool(:pure_ssh_protocol_enabled) { false }
      end
      settings :pat do
        bool(:enabled) { true }
        array(:allowed_scopes) { [] }
      end
      string(:__version) { ConfigHelper.version_from(config, 'gitlab/KHULNASOFT_SHELL_VERSION') }
    end

    settings :khulnasoft_ui do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :rails_web do
      bool(:enabled) { true }
    end

    settings :docs_khulnasoft_com do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      port(:port, 'docs_khulnasoft_com')
    end

    settings :snowplow_micro do
      bool(:enabled) { false }
      port(:port, 'snowplow_micro')
      string(:image) { 'snowplow/snowplow-micro:latest' }
    end

    settings :khulnasoft_runner do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :omnibus_gitlab do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :charts_gitlab do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :khulnasoft_operator do
      bool(:enabled) { false }
      bool(:auto_update) { true }
    end

    settings :khulnasoft_elasticsearch_indexer do
      bool(:auto_update) { true }
      path(:__dir) { config.kdk_root.join('gitlab-elasticsearch-indexer') }
      string(:__version) { ConfigHelper.version_from(config, 'gitlab/KHULNASOFT_ELASTICSEARCH_INDEXER_VERSION') }
    end

    settings :registry do
      path(:dir) { config.kdk_root.join('container-registry') }
      bool(:auto_update) { true }
      bool(:enabled) { false }
      string(:host) { config.hostname }
      string(:listen_address) { config.listen_address }
      string(:api_host) { config.hostname }
      path(:__registry_build_bin_path) { config.registry.dir.join('bin/registry') }

      port(:port, 'registry')

      string(:__listen) { "#{host}:#{port}" }

      bool(:self_signed) { false }
      bool(:auth_enabled) { true }

      bool(:compatibility_schema1_enabled) { false }
      bool(:notifications_enabled) { false }
      bool(:read_only_maintenance_enabled) { false }
      settings(:database) do
        bool(:enabled) { false }
        string(:host) { config.geo.secondary? ? config.postgresql.geo.host : config.postgresql.host }
        integer(:port) { config.geo.secondary? ? config.postgresql.geo.port : config.postgresql.port }
        string(:dbname) { 'registry_dev' }
        string(:sslmode) { 'disable' }
      end

      string(:version) { 'v4.14.0-gitlab' }
    end

    settings :object_store do
      bool(:consolidated_form) { false }
      bool(:enabled) { false }
      string(:host) { config.listen_address }
      port(:port, 'object_store')
      port(:console_port, 'object_store_console')
      string(:backup_remote_directory) { '' }
      hash_setting(:connection) do
        {
          'provider' => 'AWS',
          'aws_access_key_id' => 'minio',
          'aws_secret_access_key' => 'kdk-minio',
          'region' => 'kdk',
          'endpoint' => "http://#{config.object_store.host}:#{config.object_store.port}",
          'path_style' => true
        }
      end
      hash_setting(:objects) do
        {
          'artifacts' => { 'bucket' => 'artifacts' },
          'backups' => { 'bucket' => 'backups' },
          'external_diffs' => { 'bucket' => 'external-diffs' },
          'lfs' => { 'bucket' => 'lfs-objects' },
          'uploads' => { 'bucket' => 'uploads' },
          'packages' => { 'bucket' => 'packages' },
          'dependency_proxy' => { 'bucket' => 'dependency-proxy' },
          'terraform_state' => { 'bucket' => 'terraform' },
          'pages' => { 'bucket' => 'pages' },
          'ci_secure_files' => { 'bucket' => 'ci-secure-files' },
          'gitaly_backups' => { 'bucket' => 'gitaly-backups' }
        }
      end
    end

    settings :khulnasoft_pages do
      bool(:enabled) { false }
      string(:host) { "#{config.listen_address}.nip.io" }
      port(:port, 'khulnasoft_pages')
      string(:__uri) { "#{config.khulnasoft_pages.host}:#{config.khulnasoft_pages.port}" }
      bool(:auto_update) { true }
      string(:secret_file) { config.kdk_root.join('gitlab-pages-secret') }
      bool(:verbose) { false }
      bool(:propagate_correlation_id) { false }
      bool(:access_control) { false }
      string(:auth_client_id) { '' }
      string(:auth_client_secret) { '' }
      bool(:enable_custom_domains) { false }
      string(:auth_scope) { 'api' }
      # random 32-byte string
      string(:__auth_secret) { SecureRandom.alphanumeric(32) }
      string(:__auth_redirect_uri) { "http://#{config.khulnasoft_pages.__uri}/auth" }
      string(:__version) { ConfigHelper.version_from(config, 'gitlab/KHULNASOFT_PAGES_VERSION') }
    end

    settings :khulnasoft_k8s_agent do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      string(:__version) { ConfigHelper.version_from(config, 'gitlab/KHULNASOFT_KAS_VERSION') }
      bool(:configure_only) { false }

      string(:agent_listen_network) { 'tcp' }
      string(:agent_listen_address) { "#{config.listen_address}:8150" }
      string(:__agent_listen_url_path) { '/-/kubernetes-agent' }
      bool(:__agent_listen_websocket) do
        config.nginx?
      end
      string(:__url_for_agentk) do
        if config.nginx?
          # kas is behind nginx
          if config.https?
            "wss://#{config.nginx.__listen_address}#{config.khulnasoft_k8s_agent.__agent_listen_url_path}"
          else
            "ws://#{config.nginx.__listen_address}#{config.khulnasoft_k8s_agent.__agent_listen_url_path}"
          end
        elsif config.khulnasoft_k8s_agent.agent_listen_network == 'tcp'
          "grpc://#{config.khulnasoft_k8s_agent.agent_listen_address}"
        else
          raise UnsupportedConfiguration, "Unsupported listen network #{config.khulnasoft_k8s_agent.agent_listen_network}"
        end
      end

      bool(:run_from_source) { false }

      string(:__command) do
        if config.khulnasoft_k8s_agent.run_from_source?
          'support/exec-cd khulnasoft-k8s-agent go run -race cmd/kas/main.go'
        else
          'khulnasoft-k8s-agent/build/kdk/bin/kas_race'
        end
      end

      string(:private_api_listen_network) { 'tcp' }
      string(:private_api_listen_address) { "#{config.listen_address}:8155" }
      string(:__private_api_secret_file) { config.khulnasoft_k8s_agent.__secret_file }
      string(:__private_api_url) { "grpc://#{config.khulnasoft_k8s_agent.private_api_listen_address}" }

      string(:k8s_api_listen_network) { 'tcp' }
      string(:k8s_api_listen_address) { "#{config.listen_address}:8154" }
      string(:__k8s_api_listen_url_path) { '/-/k8s-proxy/' }
      string(:__k8s_api_url) do
        if config.nginx?
          # kas is behind nginx
          if config.https?
            "https://#{config.nginx.__listen_address}#{config.khulnasoft_k8s_agent.__k8s_api_listen_url_path}"
          else
            "http://#{config.nginx.__listen_address}#{config.khulnasoft_k8s_agent.__k8s_api_listen_url_path}"
          end
        elsif config.khulnasoft_k8s_agent.k8s_api_listen_network == 'tcp'
          "http://#{config.khulnasoft_k8s_agent.k8s_api_listen_address}"
        else
          raise UnsupportedConfiguration, "Unsupported listen network #{config.khulnasoft_k8s_agent.k8s_api_listen_network}"
        end
      end

      string(:internal_api_listen_network) { 'tcp' }
      string(:internal_api_listen_address) { "#{config.listen_address}:8153" }
      string(:__internal_api_url) do
        case config.khulnasoft_k8s_agent.internal_api_listen_network
        when 'tcp'
          "grpc://#{internal_api_listen_address}"
        when 'unix'
          "unix://#{internal_api_listen_address}"
        else
          raise UnsupportedConfiguration, "Unsupported listen network #{config.khulnasoft_k8s_agent.internal_api_listen_network}"
        end
      end

      string(:__khulnasoft_address) { "#{config.https? ? 'https' : 'http'}://#{config.workhorse.__listen_address}" }
      string(:__khulnasoft_external_url) do
        if config.nginx?
          "#{config.https? ? 'https' : 'http'}://#{config.nginx.__listen_address}"
        else
          config.khulnasoft_k8s_agent.__khulnasoft_address
        end
      end
      string(:__config_file) { config.kdk_root.join('khulnasoft-k8s-agent-config.yml') }
      string(:__secret_file) { config.kdk_root.join('khulnasoft', '.khulnasoft_kas_secret') }
      string(:__websocket_token_secret_file) { config.kdk_root.join('gitlab-kas-websocket-token-secret') }

      string(:otlp_endpoint) { '' }
      string(:otlp_ca_certificate_file) { '' }
      string(:otlp_token_secret_file) { '' }

      settings :autoflow do
        bool(:enabled) { false }

        settings :__http_client do
          array(:allowed_ips) do
            [
              config.listen_address
            ]
          end
          array(:allowed_ports) do
            [
              80,
              443,
              config.port
            ]
          end
        end

        settings :temporal do
          # localhost:7233 is the default host:port for the Temporal dev server.
          string(:host_port) { 'localhost:7233' }
          # "default" is the default namespace of the Temporal dev server.
          string(:namespace) { 'default' }
          # The following settings are for Temporal Cloud mTLS authentication.
          bool(:enable_tls) { false }
          string(:certificate_file) { '' }
          string(:key_file) { '' }

          settings :workflow_data_encryption do
            bool(:enabled) { false }

            string(:__secret_key_file) { config.kdk_root.join('gitlab-kas-autoflow-temporal-workflow-data-encryption-secret') }

            settings :codec_server do
              string(:nginx_url_path) { '/-/autoflow/codec-server/' }

              settings :listen do
                string(:network) { 'tcp' }
                string(:address) { "#{config.listen_address}:8142" }
              end

              string(:temporal_web_ui_url) { 'https://cloud.temporal.io' }
              string(:temporal_oidc_url) { 'https://login.tmprl.cloud/.well-known/openid-configuration' }

              array(:authorized_user_emails) { [] }
            end
          end
        end
      end
    end

    settings :omniauth do
      settings :gitlab do
        bool(:enabled) { false }
        string(:app_id) { '' }
        string(:app_secret) { '' }
        string(:scope) { 'read_user' }
      end
      settings :google_oauth2 do
        bool(:enabled) { false }
        string(:client_id) { '' }
        string(:client_secret) { '' }
      end
      settings :github do
        bool(:enabled) { false }
        string(:client_id) { '' }
        string(:client_secret) { '' }
      end
      settings :group_saml do
        bool(:enabled) { false }
      end
      settings :openid_connect do
        bool(:enabled) { false }
        # See https://docs.gitlab.com/ee/administration/auth/oidc.html for more detail
        hash_setting(:args) { {} }
      end
    end

    settings :pgvector do
      bool(:enabled) { false }
      string(:repo) { 'https://github.com/pgvector/pgvector.git' }
      string(:version) { 'v0.7.2' }
      bool(:auto_update) { false }
    end

    settings :geo do
      bool(:enabled) { false }
      bool(:secondary) { false }
      string(:node_name) { config.kdk_root.basename.to_s }
      settings :registry_replication do
        bool(:enabled) { false }
        string(:primary_api_url) { 'http://localhost:5100' }
      end
      settings :experimental do
        bool(:allow_secondary_tests_in_primary) { false }
      end
    end

    settings :cells do
      bool(:enabled) { false }
      # Ensure that old/non-synced cells KDKs still work as expected
      # See https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/2309
      integer(:port_offset) { config.port_offset }
      integer(:instance_count) { 0 }
      integer(:__global_sequence_range) { CellManager::DEFAULT_SEQUENCE_RANGE }

      settings_array :instances, size: -> { config.cells.instance_count } do |i|
        integer(:id) { i + 1 + CellManager::LEGACY_CELL_ID }
        array(:__sequence_range) do
          [
            1 + ((i + 1) * parent.parent.__global_sequence_range),
            (i + 2) * parent.parent.__global_sequence_range
          ]
        end
        string(:khulnasoft_repo) { "git@gitlab.com:gitlab-org/gitlab.git" }
        hash_setting(:config, merge: true) do
          main_config = parent.config

          {
            'cells' => { 'enabled' => false },
            'khulnasoft_http_router' => { 'enabled' => false },
            # We cannot have multiple `khulnasoft_topology_service` services.
            'khulnasoft_topology_service' => { 'enabled' => false },
            'khulnasoft' => {
              'cell' => {
                'id' => id,
                'database' => {
                  'skip_sequence_alteration' => false
                }
              },
              # Enable client and use main cell's defaults
              'topology_service' => {
                'enabled' => main_config.gitlab.topology_service.enabled,
                'address' => main_config.gitlab.topology_service.address,
                'ca_file' => main_config.gitlab.topology_service.ca_file.to_s,
                'certificate_file' => main_config.gitlab.topology_service.certificate_file.to_s,
                'private_key_file' => main_config.gitlab.topology_service.private_key_file.to_s
              },
              'rails' => {
                'hostname' => main_config.hostname,
                'port' => main_config.port,
                'session_store' => {
                  'session_cookie_token_prefix' => "cell-#{id}"
                }
              }
            }
          }
        end
      end

      # postgresql_clusterwide setting is now deprecated
      settings :postgresql_clusterwide do
        string(:host) { config.postgresql.host }
        # This deliberately shares a port for postgresql
        port(:port, 'postgresql') { config.postgresql.port }
      end
    end

    settings :elasticsearch do
      bool(:enabled) { false }
      string(:version) { '8.17.4' }
      string(:__architecture) do
        case KDK::Machine.architecture
        when 'arm64'
          'aarch64'
        when 'amd64'
          'x86_64'
        else
          KDK::Machine.architecture
        end
      end
    end

    settings :zoekt do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      port(:web_port_test, 'khulnasoft-zoekt-webserver-test')
      port(:web_port_dev_1, 'khulnasoft-zoekt-webserver-development-1')
      port(:web_port_dev_2, 'khulnasoft-zoekt-webserver-development-2')
      port(:index_port_test, 'khulnasoft-zoekt-indexer-test')
      port(:index_port_dev_1, 'khulnasoft-zoekt-indexer-development-1')
      port(:index_port_dev_2, 'khulnasoft-zoekt-indexer-development-2')
      string(:indexer_version) { 'main' }
    end

    settings :duo_workflow do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      port(:port, 'duo-workflow-service')
      bool(:llm_cache) { false }
      bool(:debug) { true }

      string(:__executor_version) { ConfigHelper.version_from(config, 'gitlab/DUO_WORKFLOW_EXECUTOR_VERSION') }
      # We build the executor for linux amd64 by default as we run
      # this in docker and assume you will be using linux amd64 docker
      # images. This means it may not run directly on your host.
      string(:executor_build_os) { 'linux' }
      string(:executor_build_arch) { 'amd64' }

      string(:executor_binary_url) { "http://#{config.hostname}:#{config.port}/assets/duo-workflow-executor.tar.gz" }
    end

    settings :tracer do
      string(:build_tags) { 'tracer_static tracer_static_jaeger' }
      settings :jaeger do
        bool(:enabled) { false }
        string(:version) { '1.21.0' }
        string(:listen_address) { config.hostname }
        string(:__tracer_url) do
          http_endpoint = "http://#{config.tracer.jaeger.listen_address}:14268/api/traces"

          "opentracing://jaeger?http_endpoint=#{CGI.escape(http_endpoint)}&sampler=const&sampler_param=1"
        end

        string(:__search_url) do
          tags = CGI.escape('{"correlation_id":"__CID__"}').gsub('__CID__', '{{ correlation_id }}')

          "http://#{config.tracer.jaeger.listen_address}:16686/search?service={{ service }}&tags=#{tags}"
        end
      end
    end

    settings :nginx do
      bool(:enabled) { false }
      string(:listen_address) { config.hostname }
      string(:bin) { find_executable!('nginx') || '/usr/local/bin/nginx' }
      settings :ssl do
        string(:certificate) { 'localhost.crt' }
        string(:key) { 'localhost.key' }
      end
      settings :http do
        bool(:enabled) { false }
        port(:port, 'nginx')
      end
      settings :http2 do
        bool(:enabled) { false }
      end

      integer(:__port) { config.khulnasoft_http_router? ? http.port : config.port }
      string(:__listen_address) do
        "#{listen_address}:#{__port}"
      end

      array(:__request_buffering_off_routes) do
        [
          '/api/v\d/jobs/\d+/artifacts$',
          '\.git/git-receive-pack$',
          '\.git/ssh-upload-pack$',
          '\.git/ssh-receive-pack$',
          '\.git/gitlab-lfs/objects',
          '\.git/info/lfs/objects/batch$'
        ]
      end

      settings(:sendfile) do
        bool(:enabled) { !KDK::Machine.macos? }
      end
    end

    settings :postgresql do
      bool(:enabled) { true }
      port(:port, 'postgresql')
      path(:bin_dir) { KDK::PostgresqlUpgrader.new.bin_path_or_fallback || '/usr/local/bin' }
      path(:bin) { config.postgresql.bin_dir.join('postgres') }
      string(:replication_user) { 'khulnasoft_replication' }
      path(:dir) { config.kdk_root.join('postgresql') }
      path(:data_dir) { config.postgresql.dir.join('data') }
      string(:host) { config.postgresql.dir.to_s }
      string(:active_version) { KDK::Postgresql.target_version.to_s }
      string(:__active_host) { KDK::Postgresql.new.use_tcp? ? config.postgresql.host : '' }
      integer(:max_connections) { 100 }

      # Kept for backward compatibility. Use replica:root_directory instead
      path(:replica_dir) { config.kdk_root.join('postgresql-replica') }
      # Kept for backward compatibility. Use replica:data_directory instead
      path(:replica_data_dir) { config.postgresql.replica_dir.join('data') }

      settings :replica do
        bool(:enabled) { false }
        path(:root_directory) { config.postgresql.replica_dir } # fallback to config.postgresql.replica_dir for backward compatibility
        path(:data_directory) { config.postgresql.replica_data_dir } # fallback to config.postgresql.replica_data_dir for backward compatibility
        string(:host) { root_directory.to_s }
        port(:port1, 'pgbouncer_replica-1')
        port(:port2, 'pgbouncer_replica-2')
      end

      settings :replica_2 do
        bool(:enabled) { false }
        path(:root_directory) { config.kdk_root.join('postgresql-replica-2') }
        path(:data_directory) { root_directory.join('data') }
        string(:host) { root_directory.to_s }
        port(:port1, 'pgbouncer_replica-2-1')
        port(:port2, 'pgbouncer_replica-2-2')
      end

      settings :multiple_replicas do
        bool(:enabled) { false }
      end

      settings :geo do
        port(:port, 'postgresql_geo')
        path(:dir) { config.kdk_root.join('postgresql-geo') }
        string(:host) { config.postgresql.geo.dir.to_s }
        string(:__active_host) { KDK::PostgresqlGeo.new.use_tcp? ? config.postgresql.geo.host : '' }
      end
    end

    settings :pgbouncer_replicas do
      bool(:enabled) { false }
    end

    settings :clickhouse do
      bool(:enabled) { false }
      path(:bin) { find_executable!('clickhouse') || '/usr/bin/clickhouse' }
      path(:dir) { config.kdk_root.join('clickhouse') }
      path(:data_dir) { config.clickhouse.dir.join('data') }
      path(:log_dir) { config.kdk_root.join('log', 'clickhouse') }
      string(:log_level) { 'trace' }
      port(:http_port, 'clickhouse_http')
      port(:tcp_port, 'clickhouse_tcp')
      port(:interserver_http_port, 'clickhouse_interserver')
      integer(:max_memory_usage) { 1000 * 1000 * 1000 } # 1 GB
      integer(:max_thread_pool_size) { 1000 }
      integer(:max_server_memory_usage) { 2 * 1000 * 1000 * 1000 } # 2 GB
    end

    settings :gitaly do
      bool(:skip_compile) { config.__supports_precompiled_binaries }
      bool(:skip_setup) { false }
      path(:dir) { config.kdk_root.join('gitaly') }
      bool(:enabled) { !config.praefect? || storage_count > 1 }
      path(:address) { config.kdk_root.join('gitaly.socket') }
      path(:assembly_dir) { config.gitaly.dir.join('assembly') }
      path(:config_file) { config.gitaly.dir.join('gitaly.config.toml') }
      path(:log_dir) { config.kdk_root.join('log', 'gitaly') }
      path(:storage_dir) { config.repositories_root }
      path(:repository_storages) { config.repository_storages }
      path(:runtime_dir) { config.kdk_root.join('tmp') }
      string(:auth_token) { '' }
      bool(:auto_update) { true }
      bool(:enable_all_feature_flags) { false }
      integer(:storage_count) { 1 }
      path(:__build_path) { config.gitaly.dir.join('_build') }
      path(:__build_bin_path) { config.gitaly.__build_path.join('bin') }
      path(:__build_bin_backup_path) { config.gitaly.__build_bin_path.join('gitaly-backup') }
      path(:__gitaly_build_bin_path) { config.gitaly.__build_bin_path.join('gitaly') }
      string(:__version) { ConfigHelper.version_from(config, 'gitlab/GITALY_SERVER_VERSION') }
      array(:gitconfig) { [] }
      settings_array :__storages, size: -> { storage_count } do |i|
        string(:name) { i.zero? ? 'default' : "gitaly-#{i}" }
        path(:path) do
          if i.zero?
            parent.parent.storage_dir
          else
            File.join(config.repository_storages, 'gitaly', name)
          end
        end
      end
      settings :backup do
        bool(:enabled) { config.object_store? }
        string(:go_cloud_url) do
          bucket = config.object_store.objects['gitaly_backups']['bucket']
          connection = config.object_store.connection
          case connection['provider']
          when 'AWS'
            disable_ssl = connection['endpoint'].to_s.start_with?('http://')
            path_style = !!connection['path_style']
            region_endpoint = connection.slice('region', 'endpoint')
            other_params = "&#{URI.encode_www_form(region_endpoint)}" unless region_endpoint.empty?
            "s3://#{bucket}?awssdk=v2&disable_https=#{disable_ssl}&use_path_style=#{path_style}#{other_params}"
          when 'AzureRM'
            storage_account = connection['azure_storage_account_name']
            "azblob://#{bucket}?storage_account=#{storage_account}"
          when 'Google'
            "gs://#{bucket}"
          end
        end
      end
      settings :transactions do
        bool(:enabled) { false }
      end
      hash_setting :env do
        {
          'AWS_ACCESS_KEY_ID' => 'minio',
          'AWS_SECRET_ACCESS_KEY' => 'kdk-minio'
        }
      end
    end

    settings :praefect do
      path(:address) { config.kdk_root.join('praefect.socket') }
      path(:config_file) { config.gitaly.dir.join('praefect.config.toml') }
      bool(:enabled) { true }
      path(:__praefect_build_bin_path) { config.gitaly.__build_bin_path.join('praefect') }
      settings :database do
        string(:host) { config.geo.secondary? ? config.postgresql.geo.host : config.postgresql.host }
        integer(:port) { config.geo.secondary? ? config.postgresql.geo.port : config.postgresql.port }
        string(:dbname) { 'praefect_development' }
        string(:sslmode) { 'disable' }
      end
      integer(:node_count) { 1 }
      settings_array :__nodes, size: -> { config.praefect.node_count } do |i|
        path(:address) { config.kdk_root.join("gitaly-praefect-#{i}.socket") }
        string(:config_file) { "gitaly/gitaly-#{i}.praefect.toml" }
        path(:log_dir) { config.kdk_root.join('log', "praefect-gitaly-#{i}") }
        string(:service_name) { "praefect-gitaly-#{i}" }
        string(:storage) { "praefect-internal-#{i}" }
        path(:storage_dir) { config.repositories_root }
        path(:repository_storages) { config.repository_storages }
        path(:runtime_dir) { config.kdk_root.join('tmp') }
        array(:gitconfig) { [] }
        settings_array :__storages, size: 1 do |j|
          string(:name) { parent.parent.storage }
          path(:path) { i.zero? && j.zero? ? parent.parent.storage_dir : File.join(parent.parent.repository_storages, parent.parent.service_name, name) }
        end
      end
    end

    settings :sshd do
      string(:__log_file) do
        if config.sshd.use_khulnasoft_sshd?
          "/dev/stdout"
        else
          "#{config.khulnasoft_shell.dir}/gitlab-shell.log"
        end
      end

      string(:__listen) do
        host = config.sshd.listen_address
        host = "[#{host}]" if host.include?(':')

        "#{host}:#{config.sshd.listen_port}"
      end

      bool(:enabled) { true }
      bool(:use_khulnasoft_sshd) { true }
      string(:listen_address) { config.hostname }
      port(:listen_port, 'sshd')
      string(:user) do
        if config.sshd.use_khulnasoft_sshd?
          'git'
        else
          config.username
        end
      end
      anything(:host_key) { '' } # kept for backward compatibility in case the user did set this
      array(:host_key_algorithms) { %w[rsa ed25519] }
      array(:host_keys) do
        host_key_algorithms.map { |algorithm| config.kdk_root.join('openssh', "ssh_host_#{algorithm}_key").to_s }
          .append(host_key)
          .reject(&:empty?).uniq
      end

      # gitlab-sshd only
      bool(:proxy_protocol) { false }
      string(:web_listen) do
        if config.prometheus?
          "#{config.listen_address}:#{config.prometheus.khulnasoft_shell_exporter_port}"
        else
          ""
        end
      end

      # OpenSSH only
      path(:bin) { find_executable!('sshd') || '/usr/local/sbin/sshd' }
      string(:additional_config) { '' }
      path(:authorized_keys_file) { config.kdk_root.join('.ssh', 'authorized_keys') }
    end

    settings :git do
      path(:bin) { find_executable!('git') || '/usr/local/bin/git' }
    end

    settings :runner do
      path(:config_file) { config.kdk_root.join('gitlab-runner-config.toml') }
      bool(:enabled) { false }
      integer(:concurrent) { 1 }
      string(:install_mode) { "binary" }
      string(:executor) { "docker" }
      array(:extra_hosts) { [] }
      string(:token) { 'DEFAULT TOKEN: Register your runner to get a valid token' }
      string(:image) { "gitlab/gitlab-runner:latest" }
      string(:docker_pull) { 'always' }
      string(:pull_policy) { "if-not-present" }
      string(:docker_host) { "" }
      path(:bin) { find_executable!('gitlab-runner') || '/usr/local/bin/gitlab-runner' }
      bool(:network_mode_host) { false }
      bool(:__network_mode_host) do
        raise UnsupportedConfiguration, 'runner.network_mode_host is only supported on Linux' if config.runner.network_mode_host && !KDK::Machine.linux?

        config.runner.network_mode_host
      end
      bool(:__install_mode_binary) { config.runner? && config.runner.install_mode == "binary" }
      bool(:__install_mode_docker) { config.runner? && config.runner.install_mode == "docker" }
      string(:__ssl_certificate) { Pathname.new(File.basename(config.nginx.ssl.certificate)).sub_ext('.crt') }
      string(:__add_host_flags) { config.runner.extra_hosts.map { |h| "--add-host='#{h}'" }.join(" ") }
    end

    settings :grafana do
      bool(:enabled) { false }
      port(:port, 'grafana')
      anything(:__uri) { URI::HTTP.build(host: config.hostname, port: port) }
    end

    settings :prometheus do
      bool(:enabled) { false }
      port(:port, 'prometheus')
      anything(:__uri) { URI::HTTP.build(host: config.hostname, port: port) }
      port(:gitaly_exporter_port, 'gitaly_exporter')
      port(:praefect_exporter_port, 'praefect_exporter')
      port(:workhorse_exporter_port, 'workhorse_exporter')
      port(:khulnasoft_shell_exporter_port, 'khulnasoft_shell_exporter')
      port(:khulnasoft_ai_gateway_exporter_port, 'khulnasoft_ai_gateway_exporter')
      array(:extra_hosts) { [] }
      string(:__add_host_flags) { config.prometheus.extra_hosts.map { |h| "--add-host='#{h}'" }.join(" ") }
    end

    settings :openbao do
      bool(:enabled) { false }
      bool(:auto_update) { true }
      path(:bin) { config.kdk_root.join('openbao', 'bin', 'bao') }
      string(:__server_command) { "#{bin} server --config #{config.kdk_root.join('openbao', 'config.hcl')}" }
      string(:dev_token) { 'dev-only-token' }
      string(:__listen) { "#{config.hostname}:#{port}" }
      port(:port, 'vault')
      port(:cluster_port, 'openbao_cluster')
      string(:root_token) { '' }
      string(:unseal_key) { '' }

      settings :vault_proxy do
        bool(:enabled) { parent.enabled }
        path(:bin) { parent.bin }
        string(:__server_command) { "#{bin} proxy --config #{config.kdk_root.join('openbao', 'proxy_config.hcl')}" }
        string(:__listen) { "#{config.hostname}:#{port}" }
        port(:port, 'vault_proxy')
      end
    end

    settings :openldap do
      bool(:enabled) { false }
      settings :main do
        string(:host) { config.hostname }
      end
      settings :alt do
        string(:host) { config.hostname }
      end
    end

    settings :smartcard do
      bool(:enabled) { false }
      string(:hostname) { 'smartcard.kdk.test' }
      port(:port, 'smartcard_nginx')
      bool(:san_extensions) { true }
      settings :ssl do
        string(:certificate) { 'smartcard.kdk.test.pem' }
        string(:key) { 'smartcard.kdk.test-key.pem' }
        string(:client_cert_ca) { '/mkcert/rootCA.pem' }
      end
    end

    settings :mattermost do
      bool(:enabled) { false }
      port(:port, 'mattermost')
      string(:image) { 'mattermost/mattermost-preview' }
    end

    settings :gitlab do
      bool(:auto_update) { true }
      string(:default_branch) { 'master' }
      bool(:lefthook_enabled) { true }
      path(:dir) { config.kdk_root.join('khulnasoft') }
      path(:log_dir) { config.gitlab.dir.join('log') }
      bool(:cache_classes) { false }
      bool(:gitaly_disable_request_limits) { false }

      settings :rails do
        string(:hostname) { config.hostname }
        integer(:port) { config.port }

        settings :https do
          bool(:enabled) { config.https? }
        end

        bool(:bootsnap) { true }
        string(:address) { '' }
        string(:__bind) { "#{config.gitlab.rails.__listen_settings.__protocol}://#{config.gitlab.rails.__listen_settings.__address}" }
        string(:__workhorse_url) do
          if config.gitlab.rails.address.empty?
            config.gitlab.rails.__socket_file
          else
            "http://#{config.gitlab.rails.__listen_settings.__address}"
          end
        end
        path(:__socket_file) { config.kdk_root.join('gitlab.socket') }
        string(:__socket_file_escaped) { CGI.escape(config.gitlab.rails.__socket_file.to_s) }

        settings :__listen_settings do
          string(:__protocol) do
            if config.gitlab.rails.address.empty?
              'unix'
            else
              'tcp'
            end
          end

          string(:__address) do
            if config.gitlab.rails.address.empty?
              config.gitlab.rails.__socket_file
            else
              config.gitlab.rails.address
            end
          end
        end

        bool(:__has_jh_dir) { File.exist?(config.gitlab.dir.join('jh')) }

        string(:bundle_gemfile) do
          if __has_jh_dir
            config.gitlab.dir.join('jh/Gemfile')
          else
            config.gitlab.dir.join('Gemfile')
          end
        end

        # Deprecated, use :databases settings instead
        bool(:multiple_databases) { false }

        settings :databases do
          settings :ci do
            bool(:enabled) { true }
            bool(:use_main_database) { false }

            bool(:__enabled) do
              config.gitlab.rails.multiple_databases || config.gitlab.rails.databases.ci.enabled
            end

            bool(:__use_main_database) do
              if config.gitlab.rails.multiple_databases
                false
              elsif config.gitlab.rails.databases.ci.enabled
                config.gitlab.rails.databases.ci.use_main_database
              else
                false
              end
            end
          end

          settings :sec do
            bool(:enabled) { false }
            bool(:use_main_database) { true }

            bool(:__enabled) do
              config.gitlab.rails.multiple_databases || config.gitlab.rails.databases.sec.enabled
            end

            bool(:__use_main_database) do
              if config.gitlab.rails.multiple_databases
                true
              elsif config.gitlab.rails.databases.sec.enabled
                config.gitlab.rails.databases.sec.use_main_database
              else
                true
              end
            end
          end

          settings :embedding do
            bool(:enabled) { false }
            bool(:__enabled) { enabled }
          end
        end

        settings :puma do
          integer(:workers) { 2 }

          integer(:threads_max) { 4 }
          integer(:__threads_max) { [config.gitlab.rails.puma.__threads_min, config.gitlab.rails.puma.threads_max].max }
          integer(:threads_min) { 1 }
          integer(:__threads_min) { config.gitlab.rails.puma.workers.zero? ? config.gitlab.rails.puma.threads_max : config.gitlab.rails.puma.threads_min }
        end

        settings :session_store do
          # unique_cookie_key_postfix: Unique key postfix based on the root directory of KDK
          #    We enable it by default if all cells functionality is disabled.
          #    Therefore, excluding the primary cell, keeps it `false`.
          bool(:unique_cookie_key_postfix) { !config.gitlab.topology_service.enabled? && !config.khulnasoft_topology_service.enabled }
          string(:cookie_key) { "_khulnasoft_session" }
          string(:session_cookie_token_prefix) do
            config.gitlab.topology_service.enabled? ? "cell-#{config.gitlab.cell.id}" : ""
          end
        end

        array(:allowed_hosts) { [] }

        integer(:application_settings_cache_seconds) { 60 }
      end

      settings :rails_background_jobs do
        bool(:enabled) { true }
        bool(:verbose) { false }
        integer(:timeout) { config.kdk.runit_wait_secs / 2 }
        bool(:sidekiq_exporter_enabled) { false }
        port(:sidekiq_exporter_port, 'sidekiq_exporter')
        bool(:sidekiq_health_check_enabled) { false }
        port(:sidekiq_health_check_port, 'sidekiq_health_check')
        array(:sidekiq_queues) { %w[default mailers] }
        array(:sidekiq_routing_rules) do
          [
            ["*", "default"]
          ]
        end
      end

      settings :sidekiq_cron do
        bool(:enabled) { false }
        bool(:verbose) { false }
        integer(:timeout) { config.kdk.runit_wait_secs / 2 }
        array(:sidekiq_queues) { %w[cronjob] }
      end

      settings :topology_service do
        bool(:enabled) { config.khulnasoft_topology_service.enabled }
        string(:address) { "#{config.hostname}:#{config.khulnasoft_topology_service.grpc_port}" }
        path(:ca_file) { config.kdk_root.join("khulnasoft-topology-service/tmp/certs/ca-cert.pem") }
        path(:private_key_file) { config.kdk_root.join("khulnasoft-topology-service/tmp/certs/client-key.pem") }
        path(:certificate_file) { config.kdk_root.join("khulnasoft-topology-service/tmp/certs/client-cert.pem") }
      end

      settings :cell do
        integer(:id) { CellManager::LEGACY_CELL_ID }
        integer(:__legacy_cell_sequence_maxval) { CellManager::LEGACY_CELL_SEQUENCE_MAXVAL }
        settings :database do
          bool(:skip_sequence_alteration) { true }
        end
      end
    end

    settings :redis do
      bool(:enabled) { true }
      path(:dir) { config.kdk_root.join('redis') }
      path(:__socket_file) { dir.join('redis.socket') }

      settings(:databases) do
        settings(:development) do
          integer(:shared_state) { 0 } # This inherits db=0 for compatibility reasons
          integer(:queues) { 1 }
          integer(:cache) { 2 }
          integer(:repository_cache) { 2 }
          integer(:trace_chunks) { 3 }
          integer(:rate_limiting) { 4 }
          integer(:sessions) { 5 }
        end

        settings(:test) do
          integer(:shared_state) { 10 }
          integer(:queues) { 11 }
          integer(:cache) { 12 }
          integer(:repository_cache) { 12 }
          integer(:trace_chunks) { 13 }
          integer(:rate_limiting) { 14 }
          integer(:sessions) { 15 }
        end
      end

      # See doc/howto/redis.md for more detail
      hash_setting(:custom_config) { {} }
    end

    settings :redis_cluster do
      bool(:enabled) { false }
      path(:dir) { config.kdk_root.join('redis-cluster') }
      port(:dev_port_1, 'redis_cluster_dev_1') { 6000 }
      port(:dev_port_2, 'redis_cluster_dev_2') { 6001 }
      port(:dev_port_3, 'redis_cluster_dev_3') { 6002 }
      port(:test_port_1, 'redis_cluster_test_1') { 6003 }
      port(:test_port_2, 'redis_cluster_test_2') { 6004 }
      port(:test_port_3, 'redis_cluster_test_3') { 6005 }
    end

    settings :asdf do
      bool(:opt_out) { false }
      bool(:__available?) { KDK::Dependencies.asdf_available? }
    end

    settings :mise do
      bool(:enabled) { false }
    end

    settings :packages do
      path(:__dpkg_deb_path) do
        if KDK::Machine.macos?
          config.__brew_prefix_path.join('bin', 'dpkg-deb')
        else
          '/usr/bin/dpkg-deb'
        end
      end
    end
  end
end
