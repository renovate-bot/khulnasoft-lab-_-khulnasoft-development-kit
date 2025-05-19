# ---------------------------------------------------------------------------------------------
# This file is used by the KDK to get interoperability between Make and Rake with the end
# goal of getting rid of Make in the future: https://khulnasoft.com/groups/khulnasoft-org/-/epics/1556.
# This file can be generated with the `rake support/makefiles/Makefile.config.mk` task.
# ---------------------------------------------------------------------------------------------

.PHONY: Procfile
Procfile: 
	$(Q)rake Procfile

.PHONY: khulnasoft/config/cable.yml
khulnasoft/config/cable.yml: 
	$(Q)rake khulnasoft/config/cable.yml

.PHONY: khulnasoft/config/database.yml
khulnasoft/config/database.yml: 
	$(Q)rake khulnasoft/config/database.yml

.PHONY: khulnasoft/config/khulnasoft.yml
khulnasoft/config/khulnasoft.yml: 
	$(Q)rake khulnasoft/config/khulnasoft.yml

.PHONY: khulnasoft/config/puma.rb
khulnasoft/config/puma.rb: 
	$(Q)rake khulnasoft/config/puma.rb

.PHONY: khulnasoft/config/redis.queues.yml
khulnasoft/config/redis.queues.yml: 
	$(Q)rake khulnasoft/config/redis.queues.yml

.PHONY: khulnasoft/config/resque.yml
khulnasoft/config/resque.yml: 
	$(Q)rake khulnasoft/config/resque.yml

.PHONY: khulnasoft/config/session_store.yml
khulnasoft/config/session_store.yml: 
	$(Q)rake khulnasoft/config/session_store.yml

.PHONY: gitaly/gitaly.config.toml
gitaly/gitaly.config.toml: 
	$(Q)rake gitaly/gitaly.config.toml

.PHONY: gitaly/praefect.config.toml
gitaly/praefect.config.toml: 
	$(Q)rake gitaly/praefect.config.toml

.PHONY: khulnasoft/config/redis.rate_limiting.yml
khulnasoft/config/redis.rate_limiting.yml: 
	$(Q)rake khulnasoft/config/redis.rate_limiting.yml

.PHONY: khulnasoft/config/redis.cache.yml
khulnasoft/config/redis.cache.yml: 
	$(Q)rake khulnasoft/config/redis.cache.yml

.PHONY: khulnasoft/config/redis.repository_cache.yml
khulnasoft/config/redis.repository_cache.yml: 
	$(Q)rake khulnasoft/config/redis.repository_cache.yml

.PHONY: khulnasoft/config/redis.sessions.yml
khulnasoft/config/redis.sessions.yml: 
	$(Q)rake khulnasoft/config/redis.sessions.yml

.PHONY: khulnasoft/config/redis.shared_state.yml
khulnasoft/config/redis.shared_state.yml: 
	$(Q)rake khulnasoft/config/redis.shared_state.yml

.PHONY: khulnasoft/config/redis.trace_chunks.yml
khulnasoft/config/redis.trace_chunks.yml: 
	$(Q)rake khulnasoft/config/redis.trace_chunks.yml

.PHONY: khulnasoft-topology-service/config.toml
khulnasoft-topology-service/config.toml: 
ifeq ($(khulnasoft_topology_service_enabled),true)
	$(Q)rake khulnasoft-topology-service/config.toml
else
	@true
endif

.PHONY: khulnasoft/config/vite.kdk.json
khulnasoft/config/vite.kdk.json: 
	$(Q)rake khulnasoft/config/vite.kdk.json

.PHONY: khulnasoft/workhorse/config.toml
khulnasoft/workhorse/config.toml: 
	$(Q)rake khulnasoft/workhorse/config.toml

.PHONY: khulnasoft-k8s-agent-config.yml
khulnasoft-k8s-agent-config.yml: 
	$(Q)rake khulnasoft-k8s-agent-config.yml

.PHONY: khulnasoft-kas-websocket-token-secret
khulnasoft-kas-websocket-token-secret: 
	$(Q)rake khulnasoft-kas-websocket-token-secret

.PHONY: khulnasoft-kas-autoflow-temporal-workflow-data-encryption-secret
khulnasoft-kas-autoflow-temporal-workflow-data-encryption-secret: 
	$(Q)rake khulnasoft-kas-autoflow-temporal-workflow-data-encryption-secret

.PHONY: khulnasoft-pages/khulnasoft-pages.conf
khulnasoft-pages/khulnasoft-pages.conf: khulnasoft-pages/.git/pull
	$(Q)rake khulnasoft-pages/khulnasoft-pages.conf

.PHONY: khulnasoft-pages-secret
khulnasoft-pages-secret: 
	$(Q)rake khulnasoft-pages-secret

.PHONY: khulnasoft-runner-config.toml
khulnasoft-runner-config.toml: 
ifeq ($(runner_enabled),true)
	$(Q)rake khulnasoft-runner-config.toml
else
	@true
endif

.PHONY: khulnasoft-shell/config.yml
khulnasoft-shell/config.yml: khulnasoft-shell/.git
	$(Q)rake khulnasoft-shell/config.yml

.PHONY: grafana/grafana.ini
grafana/grafana.ini: 
	$(Q)rake grafana/grafana.ini

.PHONY: nginx/conf/nginx.conf
nginx/conf/nginx.conf: 
	$(Q)rake nginx/conf/nginx.conf

.PHONY: openbao/config.hcl
openbao/config.hcl: 
ifeq ($(openbao_enabled),true)
	$(Q)rake openbao/config.hcl
else
	@true
endif

.PHONY: openbao/proxy_config.hcl
openbao/proxy_config.hcl: 
ifeq ($(openbao_enabled),true)
	$(Q)rake openbao/proxy_config.hcl
else
	@true
endif

.PHONY: openssh/sshd_config
openssh/sshd_config: 
	$(Q)rake openssh/sshd_config

.PHONY: prometheus/prometheus.yml
prometheus/prometheus.yml: 
	$(Q)rake prometheus/prometheus.yml

.PHONY: redis/redis.conf
redis/redis.conf: 
	$(Q)rake redis/redis.conf

.PHONY: registry/config.yml
registry/config.yml: registry_host.crt
	$(Q)rake registry/config.yml

.PHONY: snowplow/snowplow_micro.conf
snowplow/snowplow_micro.conf: 
	$(Q)rake snowplow/snowplow_micro.conf

.PHONY: snowplow/iglu.json
snowplow/iglu.json: 
	$(Q)rake snowplow/iglu.json

.PHONY: clickhouse/config.xml
clickhouse/config.xml: 
	$(Q)rake clickhouse/config.xml

.PHONY: clickhouse/users.xml
clickhouse/users.xml: 
	$(Q)rake clickhouse/users.xml

.PHONY: clickhouse/config.d/data-paths.xml
clickhouse/config.d/data-paths.xml: 
	$(Q)rake clickhouse/config.d/data-paths.xml

.PHONY: clickhouse/config.d/kdk.xml
clickhouse/config.d/kdk.xml: 
	$(Q)rake clickhouse/config.d/kdk.xml

.PHONY: clickhouse/config.d/logger.xml
clickhouse/config.d/logger.xml: 
	$(Q)rake clickhouse/config.d/logger.xml

.PHONY: clickhouse/config.d/openssl.xml
clickhouse/config.d/openssl.xml: 
	$(Q)rake clickhouse/config.d/openssl.xml

.PHONY: clickhouse/config.d/user-directories.xml
clickhouse/config.d/user-directories.xml: 
	$(Q)rake clickhouse/config.d/user-directories.xml

.PHONY: clickhouse/users.d/kdk.xml
clickhouse/users.d/kdk.xml: 
	$(Q)rake clickhouse/users.d/kdk.xml

.PHONY: siphon/config.yml
siphon/config.yml: 
ifeq ($(siphon_enabled),true)
	$(Q)rake siphon/config.yml
else
	@true
endif

.PHONY: siphon/consumer.yml
siphon/consumer.yml: 
ifeq ($(siphon_enabled),true)
	$(Q)rake siphon/consumer.yml
else
	@true
endif

.PHONY: elasticsearch/config/elasticsearch.yml
elasticsearch/config/elasticsearch.yml: 
ifeq ($(elasticsearch_enabled),true)
	$(Q)rake elasticsearch/config/elasticsearch.yml
else
	@true
endif

.PHONY: elasticsearch/config/jvm.options.d/custom.options
elasticsearch/config/jvm.options.d/custom.options: 
ifeq ($(elasticsearch_enabled),true)
	$(Q)rake elasticsearch/config/jvm.options.d/custom.options
else
	@true
endif

.PHONY: pgbouncers/pgbouncer-replica-1.ini
pgbouncers/pgbouncer-replica-1.ini: 
	$(Q)rake pgbouncers/pgbouncer-replica-1.ini

.PHONY: pgbouncers/pgbouncer-replica-2.ini
pgbouncers/pgbouncer-replica-2.ini: 
	$(Q)rake pgbouncers/pgbouncer-replica-2.ini

.PHONY: pgbouncers/pgbouncer-replica-2-1.ini
pgbouncers/pgbouncer-replica-2-1.ini: 
	$(Q)rake pgbouncers/pgbouncer-replica-2-1.ini

.PHONY: pgbouncers/pgbouncer-replica-2-2.ini
pgbouncers/pgbouncer-replica-2-2.ini: 
	$(Q)rake pgbouncers/pgbouncer-replica-2-2.ini

.PHONY: pgbouncers/userlist.txt
pgbouncers/userlist.txt: 
	$(Q)rake pgbouncers/userlist.txt

.PHONY: consul/config.json
consul/config.json: 
	$(Q)rake consul/config.json

.PHONY: preflight-checks
preflight-checks: preflight-checks-timed

.PHONY: preflight-checks-run
preflight-checks-run: rake
	$(Q)rake preflight-checks

.PHONY: preflight-update-checks
preflight-update-checks: preflight-update-checks-timed

.PHONY: preflight-update-checks-run
preflight-update-checks-run: rake
	$(Q)rake preflight-update-checks

