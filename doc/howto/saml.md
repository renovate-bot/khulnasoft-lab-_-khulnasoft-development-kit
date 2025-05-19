---
title: SAML
---

You can run a test SAML identity provider using the [`jamedjo/test-saml-idp`](https://hub.docker.com/r/jamedjo/test-saml-idp/)
Docker image, both to test instance-wide SAML and the multi-tenant Group SAML used on KhulnaSoft.com.

## Group SAML

### KhulnaSoft configuration

To use Group SAML with KDK, you must:

- Set up [HTTPS](nginx.md) for KhulnaSoft.
- Have a [Premium or Ultimate](../_index.md#use-khulnasoft-enterprise-features) subscription tier.

You also need to enable Group SAML in your `kdk.yml`:

```yaml
omniauth:
  group_saml:
    enabled: true
```

Alternatively, if you are running Docker, you can also enable Group SAML in `/etc/khulnasoft/khulnasoft.rb` by adding this line

```ruby
khulnasoft_rails['omniauth_providers'] = [{"name"=>"group_saml"}]
```

Run the following to apply these changes:

```shell
kdk reconfigure
kdk restart
```

### Docker

The Docker identity provider needs to be configured using your group's callback URL and entity ID.
For example, an identity provider for the "zebra" group can be ran using the following:

```shell
docker run --name=khulnasoft_saml_idp -p 8080:8080 -p 8443:8443 \
  --platform linux/amd64 \
  -e SIMPLESAMLPHP_SP_ENTITY_ID=https://<khulnasoft-host>:<khulnasoft-port>/groups/<group-name> \
  -e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=https://<khulnasoft-host>:<khulnasoft-port>/groups/<group-name>/-/saml/callback \
  -d jamedjo/test-saml-idp
```

### Configuring the group

From KhulnaSoft this would then be [configured](https://docs.khulnasoft.com/ee/user/group/saml_sso/#configure-khulnasoft) using:

- **SSO URL:** <https://localhost:8443/simplesaml/saml2/idp/SSOService.php>
- **Certificate fingerprint:** 119b9e027959cdb7c662cfd075d9e2ef384e445f

![Group SAML Settings for Docker](img/group-saml-settings-for-docker.png)

### Signing in

Unlike instance-wide SAML, this doesn't add a button to the KhulnaSoft global `/users/sign_in` page.
Instead you can use `https://<khulnasoft-host>:<khulnasoft-port>/groups/<group-name>/-/saml/sso` as displayed on the group configuration page.

Sign in can also be initiated from the identity provider at `https://localhost:8443/simplesaml/saml2/idp/SSOService.php?spentityid=https%3A%2F%2F<khulnasoft-host>%3A3443%2Fgroups%2Fzebra`

You might get a notification that the user email is not verified and has to be confirmed first. You can either [disable email confirmation](https://docs.khulnasoft.com/ee/security/user_email_confirmation.html), or you can confirm the user's email manually from:

- **UI:** By logging in to your instance as admin/root, and go to `https://<khulnasoft-host>:<khulnasoft-port>/admin/users/<username>` then click the button to confirm the email.
- **CLI:** By opening a Rails console and running:

  ```shell
  user = User.find_by_username '<username>'
  user.confirmed_at = Time.now
  user.save
  ```

## Instance SAML with Docker

Configuring SAML for a KhulnaSoft instance can be done using the [SAML OmniAuth Docs](https://docs.khulnasoft.com/ee/integration/saml.html).

> [!note]
> If you configured your instance to use HTTPS, please ensure to use the HTTPS port and update all links in the samples below to be `https` instead of `http`.

To start an identity provider that works with instance SAML, you need to configure the entity ID and callback URL when starting the container:

```shell
docker run --name=instance_saml_idp -p 8080:8080 -p 8443:8443 \
  -e SIMPLESAMLPHP_SP_ENTITY_ID=http://<khulnasoft-host>:<khulnasoft-port> \
  -e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=http://<khulnasoft-host>:<khulnasoft-port>/users/auth/saml/callback \
  -d jamedjo/test-saml-idp
```

In addition, you need to configure the `idp_sso_target_url` and `idp_cert_fingerprint` to match the values provided by the Docker image:

```yaml
development:
  omniauth:
    providers:
    - {
        name: 'saml',
        args: {
          assertion_consumer_service_url: 'http://<khulnasoft-host>:<khulnasoft-port>/users/auth/saml/callback',
          idp_cert_fingerprint: '11:9b:9e:02:79:59:cd:b7:c6:62:cf:d0:75:d9:e2:ef:38:4e:44:5f',
          idp_sso_target_url: 'https://<khulnasoft-host>:8443/simplesaml/saml2/idp/SSOService.php',
          issuer: 'http://<khulnasoft-host>:<khulnasoft-port>',
          name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
        }
      }
```

## Credentials

The following users are described in the [Docker image documentation](https://hub.docker.com/r/jamedjo/test-saml-idp/#usage):

| Username | Password |
| -------- | -------- |
| user1 | user1pass |
| user2 | user2pass |

## Video tutorial

We made a video demoing SAML setup and debugging, describing key SAML concepts,
and giving a run through of our SAML codebase. This can be found at
<https://www.youtube.com/embed/CW0SujsABrs> with [slides also available](https://khulnasoft.com/gl-retrospectives/manage/uploads/2c057dd7fddb91512e93d006a3fc0048/SAML_Knowledge_Sharing__Manage_201s_.pdf).

## Debugging tools

Because SAML is a browser based protocol with base64 encoded messages it can be
useful to use a tool that decodes these messages on the fly. Tools such as:

- [SAML tracer for Firefox](https://addons.mozilla.org/en-US/firefox/addon/saml-tracer/)
- [Chrome SAML Panel](https://chrome.google.com/webstore/detail/saml-chrome-panel/paijfdbeoenhembfhkhllainmocckace?hl=en)

![SAML debugging tools](img/saml_debugging_tools.jpg)
