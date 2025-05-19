khulnasoft_openldap_root = $(shell pwd)

default: slapd.d/bootstrap contents alt_contents
large: default slapd.d/large-db

contents: slapd.d/schema slapd.d/example-com
alt_contents: slapd.d/schema slapd.d/alt-example-com

slapd.d:
	mkdir slapd.d
	chmod 700 slapd.d

slapd.d/bootstrap: sbin/slapadd slapd.d
	sbin/slapadd -n 0 -F slapd.d < bootstrap.ldif
	touch $@

slapd.d/schema: sbin/slapadd
	sbin/slapadd -b 'cn=config' -F slapd.d < etc/openldap/schema/core.ldif
	sbin/slapadd -b 'cn=config' -F slapd.d < etc/openldap/schema/cosine.ldif
	sbin/slapadd -b 'cn=config' -F slapd.d < etc/openldap/schema/inetorgperson.ldif
	sbin/slapadd -b 'cn=config' -F slapd.d < etc/openldap/schema/nis.ldif
	touch $@

slapd.d/example-com: sbin/slapadd
	sbin/slapadd -b 'dc=example,dc=com' -F slapd.d < frontend.example.com.ldif
	touch $@

slapd.d/alt-example-com: sbin/slapadd
	sbin/slapadd -b 'dc=example-alt,dc=com' -F slapd.d < frontend.alt.example.com.ldif
	touch $@

slapd.d/large-db:	sbin/slapadd
	./large-db-ldif 10000 | sbin/slapadd -b 'dc=example,dc=com' -F slapd.d
	touch $@

clean:
	rm -rf slapd.d

disable_bind_anon:
	bin/ldapmodify -H ldap://127.0.0.1:3890/ -D "cn=admin,cn=config" -w password -f disable_bind_anon.ldif

openldap-2.6.8:
	curl -OL https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.6.8.tgz
	echo '48969323e94e3be3b03c6a132942dcba7ef8d545f2ad35401709019f696c3c4e *openldap-2.6.8.tgz' | shasum -a256 -c -
	tar zxf openldap-2.6.8.tgz

sbin/slapadd: openldap-2.6.8
	cd openldap-2.6.8 && ./configure --prefix=${khulnasoft_openldap_root} --enable-bdb=no --enable-hdb=no
	cd openldap-2.6.8 && make -j 2 install

.PHONY: clean default large contents alt_contents disable_bind_anon
