ifeq ($(elasticsearch_enabled),true)
elasticsearch-setup: elasticsearch/bin/elasticsearch
else
elasticsearch-setup:
	@true
endif

elasticsearch/bin/elasticsearch: elasticsearch/lib/elasticsearch-${elasticsearch_version}.jar elasticsearch/config/elasticsearch.yml elasticsearch/config/jvm.options.d/custom.options

elasticsearch/lib/elasticsearch-${elasticsearch_version}.jar:
	$(Q)rm -rf elasticsearch && mkdir -p elasticsearch
	$(Q)curl -C - -L --fail "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${elasticsearch_version}-${platform}-${elasticsearch_architecture}.tar.gz" | tar xzf - --strip-components=1 -C elasticsearch --exclude=config/elasticsearch.yml
