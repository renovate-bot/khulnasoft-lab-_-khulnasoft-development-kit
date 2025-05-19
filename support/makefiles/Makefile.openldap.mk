.PHONY: openldap-setup
ifeq ($(openldap_enabled),true)
openldap-setup: khulnasoft-openldap/libexec/slapd .cache/khulnasoft-openldap_ldap-users-created
else
openldap-setup:
	@true
endif

khulnasoft-openldap/libexec/slapd:
	$(Q)make -C khulnasoft-openldap sbin/slapadd

.cache/khulnasoft-openldap_ldap-users-created:
	$(Q)make -C khulnasoft-openldap default
	$(Q)touch $@
