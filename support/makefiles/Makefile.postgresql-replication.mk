psql := $(postgresql_bin_dir)/psql

.PHONY: postgresql-replica-setup
ifeq ($(postgresql_replica_enabled),true)
postgresql-replica-setup: postgresql-replication/config postgresql-replica/data
else
postgresql-replica-setup:
	@true
endif

.PHONY: postgresql-replica-2-setup
ifeq ($(postgresql_replica_enabled2),true)
postgresql-replica-2-setup: postgresql-replication/config postgresql-replica-2/data
else
postgresql-replica-2-setup:
	@true
endif

postgresql-replica/data:
	pg_basebackup -R -h ${postgresql_dir} -D ${postgresql_replica_data_dir} -P -U khulnasoft_replication --wal-method=fetch

postgresql-replica-2/data:
	pg_basebackup -R -h ${postgresql_dir} -D ${postgresql_replica_data_dir2} -P -U khulnasoft_replication --wal-method=fetch

postgresql-replication-primary-create-slot: postgresql-replication/slot

postgresql-replication/backup:
	$(Q)bundle exec rake geo:replication_backup
	$(Q)$(MAKE) ${postgresql_data_dir}/gitlab.conf ${QQ}

postgresql-replication/slot:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_create_physical_replication_slot('khulnasoft_kdk_replication_slot');"

postgresql-replication/list-slots:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "SELECT * FROM pg_replication_slots;"

postgresql-replication/drop-slot:
	$(Q)$(psql) -h ${postgresql_host} -p ${postgresql_port} -d postgres -c "SELECT pg_drop_replication_slot('khulnasoft_kdk_replication_slot');" 2>/dev/null || echo "Replication slot 'khulnasoft_kdk_replication_slot' does not exist"

postgresql-replication/config:
	$(Q)./support/postgres-replication
