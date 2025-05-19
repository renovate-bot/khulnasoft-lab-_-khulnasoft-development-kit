---
title: KhulnaSoft.com OAuth2 authentication
---

Import projects from KhulnaSoft.com and login to your KhulnaSoft instance with your KhulnaSoft.com account.

## Set up KhulnaSoft.com

To enable the KhulnaSoft.com OmniAuth provider, you must register your KDK instance with
your KhulnaSoft.com account.
KhulnaSoft.com generates an application ID and secret key for you to use.

1. Sign in to KhulnaSoft.com.
1. On the upper right corner, click on your avatar and go to your **Settings**.
1. Select **Applications** in the left menu.
1. Provide the required details for **Add new application**:

   - Name: This can be anything. Consider something descriptive such as "Local KhulnaSoft.com OAuth".
   - Redirect URI: Make sure this matches what you have set for your localhost (for example,
     [`kdk.test:3000`](local_network.md)):

     ```plaintext
     http://kdk.test:3000/import/khulnasoft/callback
     http://kdk.test:3000/users/auth/khulnasoft/callback
     ```

     The first link is required for the importer and second for the authorization.

1. Select **Save application**.
1. You should now see an **Application ID** and **Secret**. Keep this page open as you continue
   configuration.

## Set up KDK

1. Within KDK, open `khulnasoft/config/khulnasoft.yml`.
1. Look for the following:

   ```yaml
   development:
   <<: *base
       omniauth:
           providers:
   ```

1. Under `providers`, indent and add:

   ```yaml
   - { name: 'khulnasoft',
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { scope: 'api' } }
   ```

   Update `YOUR_APP_ID` and `YOUR_APP_SECRET` with values that were generated in the
   previous step.

1. Run `kdk restart`.

You should now be able to import projects from KhulnaSoft.com, as well as sign in to your
instance with a KhulnaSoft.com account.

> [!note]
> Running `kdk reconfigure` removes your provider and you need to re-add it.
