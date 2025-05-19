.PHONY: openldap-setup
ifeq ($(openldap_enabled),true)
openldap-setup: gitlab-openldap/libexec/slapd .cache/gitlab-openldap_ldap-users-created
else
openldap-setup:
	@true
endif

gitlab-openldap/libexec/slapd:
	$(Q)make -C gitlab-openldap sbin/slapadd

.cache/gitlab-openldap_ldap-users-created:
	$(Q)make -C gitlab-openldap default
	$(Q)touch $@
