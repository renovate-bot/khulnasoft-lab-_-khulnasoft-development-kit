# frozen_string_literal: true

module KDK
  module TaskHelpers
    # A rake or make task
    Task = Struct.new(:name, :make_dependencies, :rake_dependencies, :template,
      :erb_extra_args, :post_render, :generate_makefile_target,
      :no_op_condition, :timed, :hide_diff, keyword_init: true) do
      def initialize(attributes)
        super

        template = "support/templates/#{self[:name]}.erb"
        self[:template] ||= template

        self[:rake_dependencies] = attributes[:rake_dependencies] || []
        self[:make_dependencies] = (attributes[:make_dependencies] || []).join(' ')
        self[:erb_extra_args] ||= {}
        self[:generate_makefile_target] = attributes.fetch(:generate_makefile_target, true)
        self[:timed] = false if self[:timed].nil?
        # Turn no_op_condition: 'khulnasoft_topology_service_enabled', into `config.khulnasoft_topology_service.enabled`.
        @enabled = self[:no_op_condition] ? KDK.config.dig(self[:no_op_condition].delete_suffix('_enabled'), 'enabled') : true
      end

      def enabled?
        @enabled
      end
    end

    # Class to handle config tasks templates and make targets
    class ConfigTasks
      def self.build
        @tasks ||= new.tap do |tasks|
          define_template_tasks(tasks)
          define_make_tasks(tasks)
          # This should be the last task.
          define_makefile_config_task(tasks)
        end
      end

      # rubocop:disable Metrics/AbcSize -- A set of definitions which could be split up per component later
      def self.define_template_tasks(tasks)
        tasks.add_template(name: 'Procfile')
        tasks.add_template(name: 'gitlab/config/cable.yml')
        tasks.add_template(name: 'khulnasoft/config/database.yml')
        tasks.add_template(name: 'gitlab/config/gitlab.yml')
        tasks.add_template(name: 'gitlab/config/puma.rb')
        tasks.add_template(name: 'gitlab/config/redis.queues.yml', template: 'support/templates/khulnasoft/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :queues })
        tasks.add_template(name: 'gitlab/config/resque.yml', template: 'support/templates/khulnasoft/config/redis.sessions.yml.erb', erb_extra_args: { cluster: :shared_state })
        tasks.add_template(name: 'gitlab/config/session_store.yml')

        tasks.add_template(name: 'gitaly/gitaly.config.toml', erb_extra_args: { node: KDK.config.gitaly }, post_render: lambda do |_task|
          KDK.config.gitaly.__storages.each do |storage|
            FileUtils.mkdir_p(storage.path)
          end

          FileUtils.mkdir_p(KDK.config.gitaly.log_dir)
          FileUtils.mkdir_p(KDK.config.gitaly.runtime_dir)
          FileUtils.mkdir_p(KDK.config.kdk_root.join('gitaly-custom-hooks'))
        end)

        tasks.add_template(name: 'gitaly/praefect.config.toml', post_render: lambda do |_task|
          KDK.config.praefect.__nodes.each_with_index do |node, _|
            Rake::Task[node['config_file']].invoke
          end
        end)

        KDK.config.praefect.__nodes.each do |node|
          tasks.add_template(name: node['config_file'], template: 'support/templates/gitaly/gitaly.config.toml.erb', erb_extra_args: { node: node }, generate_makefile_target: false, post_render: lambda do |_task|
            node.__storages.each do |storage|
              FileUtils.mkdir_p(storage.path)
            end

            FileUtils.mkdir_p(node['log_dir'])
            FileUtils.mkdir_p(node['runtime_dir'])
          end)
        end

        %i[rate_limiting cache repository_cache sessions shared_state trace_chunks].each do |name|
          kwargs = if KDK.config.redis_cluster.enabled?
                     {
                       name: "gitlab/config/redis.#{name}.yml",
                       template: 'support/templates/khulnasoft/config/redis.cluster.yml.erb'
                     }
                   else
                     {
                       name: "gitlab/config/redis.#{name}.yml",
                       template: 'support/templates/khulnasoft/config/redis.sessions.yml.erb',
                       erb_extra_args: { cluster: name }
                     }
                   end

          tasks.add_template(**kwargs)
        end

        tasks.add_template(name: 'khulnasoft-topology-service/config.toml', no_op_condition: 'khulnasoft_topology_service_enabled')
        tasks.add_template(name: 'gitlab/config/vite.kdk.json')
        tasks.add_template(name: 'gitlab/workhorse/config.toml')
        tasks.add_template(name: 'khulnasoft-k8s-agent-config.yml')
        tasks.add_template(name: 'gitlab-kas-websocket-token-secret', hide_diff: true)
        tasks.add_template(name: 'gitlab-kas-autoflow-temporal-workflow-data-encryption-secret', hide_diff: true)
        tasks.add_template(name: 'gitlab-pages/gitlab-pages.conf', make_dependencies: ['gitlab-pages/.git/pull'])
        tasks.add_template(name: 'gitlab-pages-secret', hide_diff: true)
        tasks.add_template(name: 'gitlab-runner-config.toml', no_op_condition: 'runner_enabled')
        tasks.add_template(name: 'gitlab-shell/config.yml', make_dependencies: ['gitlab-shell/.git'])
        tasks.add_template(name: 'grafana/grafana.ini')
        tasks.add_template(name: 'nginx/conf/nginx.conf')
        tasks.add_template(name: 'openbao/config.hcl', no_op_condition: 'openbao_enabled')
        tasks.add_template(name: 'openbao/proxy_config.hcl', no_op_condition: 'openbao_enabled')
        tasks.add_template(name: 'openssh/sshd_config')
        tasks.add_template(name: 'prometheus/prometheus.yml', post_render: ->(task) { chmod('+r', task.name, verbose: false) })
        tasks.add_template(name: 'redis/redis.conf')
        tasks.add_template(name: 'registry/config.yml', make_dependencies: ['registry_host.crt'])
        tasks.add_template(name: 'snowplow/snowplow_micro.conf', post_render: ->(task) { chmod('+r', task.name, verbose: false) })
        tasks.add_template(name: 'snowplow/iglu.json', post_render: ->(task) { chmod('+r', task.name, verbose: false) })
        tasks.add_template(name: 'clickhouse/config.xml', template: 'support/templates/clickhouse/config.xml')
        tasks.add_template(name: 'clickhouse/users.xml', template: 'support/templates/clickhouse/users.xml')
        tasks.add_template(name: 'clickhouse/config.d/data-paths.xml')
        tasks.add_template(name: 'clickhouse/config.d/kdk.xml')
        tasks.add_template(name: 'clickhouse/config.d/logger.xml')
        tasks.add_template(name: 'clickhouse/config.d/openssl.xml')
        tasks.add_template(name: 'clickhouse/config.d/user-directories.xml')
        tasks.add_template(name: 'clickhouse/users.d/kdk.xml')
        tasks.add_template(name: 'siphon/config.yml', no_op_condition: 'siphon_enabled')
        tasks.add_template(name: 'siphon/consumer.yml', no_op_condition: 'siphon_enabled')
        tasks.add_template(name: 'elasticsearch/config/elasticsearch.yml', template: 'support/templates/elasticsearch/config/elasticsearch.yml', no_op_condition: 'elasticsearch_enabled')
        tasks.add_template(name: 'elasticsearch/config/jvm.options.d/custom.options', template: 'support/templates/elasticsearch/config/jvm.options.d/custom.options', no_op_condition: 'elasticsearch_enabled')
        tasks.add_template(name: 'pgbouncers/pgbouncer-replica-1.ini', template: 'support/templates/pgbouncer/pgbouncer-replica.ini.erb', erb_extra_args: { host: KDK.config.postgresql.replica.host, port: KDK.config.postgresql.replica.port1 })
        tasks.add_template(name: 'pgbouncers/pgbouncer-replica-2.ini', template: 'support/templates/pgbouncer/pgbouncer-replica.ini.erb', erb_extra_args: { host: KDK.config.postgresql.replica.host, port: KDK.config.postgresql.replica.port2 })
        tasks.add_template(name: 'pgbouncers/pgbouncer-replica-2-1.ini', template: 'support/templates/pgbouncer/pgbouncer-replica.ini.erb', erb_extra_args: { host: KDK.config.postgresql.replica_2.host, port: KDK.config.postgresql.replica_2.port1 })
        tasks.add_template(name: 'pgbouncers/pgbouncer-replica-2-2.ini', template: 'support/templates/pgbouncer/pgbouncer-replica.ini.erb', erb_extra_args: { host: KDK.config.postgresql.replica_2.host, port: KDK.config.postgresql.replica_2.port2 })
        tasks.add_template(name: 'pgbouncers/userlist.txt', template: 'support/templates/pgbouncer/pgbouncer-userlist.txt.erb')
        tasks.add_template(name: 'consul/config.json', erb_extra_args: { min_port: 6432, max_port: 6435 })
      end
      # rubocop:enable Metrics/AbcSize

      def self.define_make_tasks(tasks)
        tasks.add_make_task(name: 'preflight-checks', timed: true)
        tasks.add_make_task(name: 'preflight-update-checks', timed: true)
      end

      def self.define_makefile_config_task(tasks)
        tasks.add_template(name: 'support/makefiles/Makefile.config.mk', template: 'support/templates/makefiles/Makefile.config.mk.erb', rake_dependencies: Dir['lib/**/*'], erb_extra_args: { tasks: tasks.all_with_makefile_target })
      end

      def initialize
        @template_tasks = []
        @make_tasks = []
      end

      def add_template(**args)
        @template_tasks << Task.new(**args)
      end

      def add_make_task(**args)
        @make_tasks << Task.new(**args)
      end

      def template_tasks
        @template_tasks.clone
      end

      def diffable_template_tasks
        template_tasks.reject(&:hide_diff)
      end

      def make_tasks
        @make_tasks.clone
      end

      def all_tasks
        template_tasks + make_tasks
      end

      def all_with_makefile_target
        all_tasks.select(&:generate_makefile_target)
      end
    end
  end
end
