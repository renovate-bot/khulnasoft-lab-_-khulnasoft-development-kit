.PHONY: geo-secondary-setup geo-cursor
geo-secondary-setup: geo-setup-check Procfile geo-cursor geo-config postgresql/geo

geo-setup-check:
ifneq ($(geo_enabled),true)
	$(Q)echo 'ERROR: geo.enabled is not set to true in your kdk.yml'
	@exit 1
else
	@true
endif

geo-config: khulnasoft/config/database.yml postgresql-geo/data/gitlab.conf

geo-cursor:
	$(Q)grep '^geo-cursor:' Procfile || (printf ',s/^#geo-cursor/geo-cursor/\nwq\n' | ed -s Procfile)
