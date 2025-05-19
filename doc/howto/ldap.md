---
title: LDAP
---

You can run an OpenLDAP daemon inside the KDK if you want to work on the
KhulnaSoft LDAP integration.

## Installation

### Enable OpenLDAP in the KDK

1. Add the following to your `<kdk-root>/kdk.yml` file:

   ```yaml
   openldap:
     enabled: true
   ```

1. Reconfigure and restart:

   ```shell
   kdk reconfigure
   kdk restart
   ```

1. On the login screen, there are now two tabs: `LDAP` and
   `LDAP-alt`. See the following table for username and password
   combinations that can be used. The users (example: `john`) with
   `dc=example` in the `DN` column can sign in on the `LDAP` tab, while
   users with `dc=example=alt` (example: `bob`) can sign in on the
   `LDAP-alt` tab.

### LDAP users

The following users are added to the LDAP server:

| uid      | Password | DN                                          |
| -------- | -------- | -------                                     |
| john     | password | `uid=john,ou=people,dc=example,dc=com`      |
| mary     | password | `uid=mary,ou=people,dc=example,dc=com`      |
| bob      | password | `uid=bob,ou=people,dc=example-alt,dc=com`   |
| alice    | password | `uid=alice,ou=people,dc=example-alt,dc=com` |

### LDAP groups

For testing of KhulnaSoft Enterprise Edition the following groups are created:

| cn            | DN                                              | Members     |
| -------       | --------                                        | ----------  |
| group1        | `cn=group1,ou=groups,dc=example,dc=com`         | john, mary  |
| group2        | `cn=group2,ou=groups,dc=example,dc=com`         | john        |
| group-a       | `cn=group-a,ou=groups,dc=example-alt,dc=com`    | bob, alice  |
| group-b       | `cn=group-b,ou=groups,dc=example-alt,dc=com`    | bob         |

### LDAP group sync

To test [LDAP group sync](https://docs.gitlab.com/ee/user/group/access_and_permissions.html#manage-group-memberships-via-ldap),
[create group links through CN](https://docs.gitlab.com/ee/user/group/access_and_permissions.html#create-group-links-via-cn)
and add a sync for `group1` or `group2`, then ensure that the correct members are
added.

### Testing with many users and groups

If you wish to create more users and groups, run:

```shell
cd <kdk-directory>/khulnasoft-openldap
make large
```

More groups will be created with the following username and group ranges:

| uid      | Password | DN                                          | Last     |
| -------- | -------- | -------                                     | ----     |
| john0    | password | `uid=john0,ou=people,dc=example,dc=com`     | john9999 |
| mary0    | password | `uid=mary0,ou=people,dc=example,dc=com`     | mary9999 |

| cn            | DN                                              | Member count | Last          |
| -------       | --------                                        | ------------ | ----          |
| group-10-0    | `cn=group-10-0,ou=groups,dc=example,dc=com`     | 10           | group-10-1000 |
| group-100-0   | `cn=group-100-0,ou=groups,dc=example,dc=com`    | 100          | group-100-100 |
| group-1000-0  | `cn=group-1000-0,ou=groups,dc=example,dc=com`   | 1,000        | group-1000-10 |
| group-10000-0 | `cn=group-10000-0,ou=groups,dc=example,dc=com`  | 10,000       | group-10000-1 |

## Manual setup instructions

```shell
cd <kdk-directory>/khulnasoft-openldap
make # compile openldap and bootstrap an LDAP server to run out of slapd.d
```

We can also simulate a large instance with many users and groups:

```shell
make large
```

Then run the daemon:

```shell
./run-slapd # stays attached in the current terminal
```

We can add individual users, groups, and their membership as well if we so desire:

```shell
 cd <kdk-directory>/khulnasoft-openldap
```

Create an LDIF file with following content. Feel free to change user, group metadata:

```shell
# User Entries

# User 1: guestuser
dn: uid=guestuser,ou=people,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: guestuser
sn: User
givenName: Guest
cn: Guest User
displayName: Guest User
uidNumber: 10001
gidNumber: 10001
# hashed value for 'password' - you may want to change this
userPassword: {SSHA}qqLFjamdd1cru4RV815+FiSxh/54rfbd
gecos: Guest User
loginShell: /bin/bash
homeDirectory: /home/guestuser
shadowExpire: -1
shadowFlag: 0
shadowWarning: 7
shadowMin: 8
shadowMax: 999999
shadowLastChange: 10877
mail: guestuser@test.com
postalCode: 10000
l: Example City
o: Example
mobile: +1 555 123 4567
title: Guest User
initials: GU

# Group Entries

# Group 1: GUEST
dn: cn=GUEST,ou=groups,dc=example,dc=com
objectClass: groupOfNames
cn: GUEST
description: Group for guest users
member: uid=guestuser,ou=people,dc=example,dc=com

```

Run an `ldapadd` command to add this to your LDAP server:

```shell
ldapadd -H "ldap://127.0.0.1:3890" -x -D "cn=admin,dc=example,dc=com" -w password -f <your new created ldif file name>.ldif
```

### Configuring KhulnaSoft

In `<kdk-directory>/gitlab/config/gitlab.yml` under `production:` and `ldap:`, change the following keys to the values
given below (see [defaults](https://github.com/khulnasoft-lab/khulnasoft/-/blob/master/config/gitlab.yml.example#L550-769)):

```yaml
  enabled: true
  servers:
    main:
      # ...
      host: 127.0.0.1
      port: 3890
      uid: 'uid'
      # ...
      base: 'dc=example,dc=com'
      group_base: 'ou=groups,dc=example,dc=com'  # Insert this
```

In KhulnaSoft EE, an alternative database can optionally be added as follows:

```yaml
    main:
      # ...
    alt:
      label: LDAP-alt
      host: 127.0.0.1
      port: 3891
      uid: 'uid'
      encryption: 'plain' # "tls" or "ssl" or "plain"
      base: 'dc=example-alt,dc=com'
      user_filter: ''
      group_base: 'ou=groups,dc=example-alt,dc=com'
      admin_group: ''
```

Run `kdk restart` to restart the modified services.

### Repopulate the database

```shell
cd <kdk-directory>/khulnasoft-openldap
make clean default
```

### Optional: disable anonymous binding

The above config does not use a bind user, to keep it as simple as possible.
If you want to disable anonymous binding and require authentication:

1. Run the following command:

   ```shell
   make disable_bind_anon
   ```

1. Update `gitlab.yml` also with the following:

   ```yaml
   ldap:
     enabled: true
     servers:
       main:
         # ...
         bind_dn: 'cn=admin,dc=example,dc=com'
         password: 'password'
         #...
   ```

### Optional: Allow authentication with smart cards

If you have [set up smart card authentication on KDK](smartcard.md), you can enable smart card authentication against the LDAP server.

1. In `<kdk-directory>/gitlab/config/gitlab.yml` under `production:` and `ldap:`, change the `smartcard_auth:` key to either `optional` or `required`:

   ```yaml
   ldap:
     enabled: true
     servers:
       main:
         # ...
         smartcard_auth: optional
   ```

1. Restart the `rails-web` process in KDK to load the new configuration:

   ```shell
   kdk restart rails-web
   ```

On the tab for the relevant LDAP server on the sign-in page, you should now see a **Sign in with smart card** button. Use this to search the LDAP server for the certificate presented by the user and allow signing in with it.

## Troubleshooting

The following commands should help validate KhulnaSoft and OpenLDAP are
configured properly. Also see the [LDAP Troubleshooting documentation](https://docs.gitlab.com/ee/administration/auth/ldap/ldap-troubleshooting.html).

### Rake task

In the `gitlab` directory, run:

```shell
bundle exec rake gitlab:ldap:check
```

You should see two sets of LDAP configurations: one for the domain
component (DC) `example` and one for `example-alt`:

```plaintext
Checking LDAP ...

LDAP: ... Server: ldapmain
LDAP authentication... Anonymous. No `bind_dn` or `password` configured
LDAP users with access to your KhulnaSoft server (only showing the first 100 results)
        DN: uid=john,ou=people,dc=example,dc=com         uid: john
        DN: uid=mary,ou=people,dc=example,dc=com         uid: Mary
Server: ldapalt
LDAP authentication... Anonymous. No `bind_dn` or `password` configured
LDAP users with access to your KhulnaSoft server (only showing the first 100 results)
        DN: uid=alice,ou=people,dc=example-alt,dc=com    uid: alice
        DN: uid=bob,ou=people,dc=example-alt,dc=com      uid: bob

Checking LDAP ... Finished
```

### ldapsearch

To validate the OpenLDAP server is running and to see what users are available:

```shell
ldapsearch -x -b "dc=example,dc=com" -H "ldap://127.0.0.1:3890"
ldapsearch -x -b "dc=example-alt,dc=com" -H "ldap://127.0.0.1:3890"
```
