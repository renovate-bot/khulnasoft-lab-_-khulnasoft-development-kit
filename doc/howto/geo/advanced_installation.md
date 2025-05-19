---
title: KhulnaSoft Geo - Advanced Installation
---

If you are looking for the one-line installation method for Geo, see [KhulnaSoft Geo - Easy installation](../geo.md#easy-installation).

## Add a secondary Geo site

Prerequisites:

- To add a secondary Geo site, you must have a KDK already installed.

1. On your existing KDK, add a KhulnaSoft Premium or Ultimate license either:

   - In the [KhulnaSoft UI](https://docs.gitlab.com/ee/administration/license_file.html).
   - Using an [environment variable](https://docs.gitlab.com/ee/administration/license_file.html#add-your-license-file-during-installation).

1. Clone KDK into a second directory adjacent to your existing KDK:

   ```shell
   git clone https://github.com/khulnasoft-lab/khulnasoft-development-kit.git kdk2
   ```

1. Change directory to your existing KDK:

   ```shell
   cd kdk
   ```

1. Run the script:

   ```shell
   ./support/geo-add-secondary --secondary-port 3001 --primary . ../kdk2
   ```

The new KDK's URL `http://127.0.0.1:3001` is the unified URL. You can still visit the primary directly if needed.

## Manual installation of a primary and secondary Geo site

### Prerequisites

Development on KhulnaSoft Geo requires two KDK instances running side-by-side. You can use an existing
KDK instance based on the [the usual installation instructions](../../_index.md#use-kdk-to-install-gitlab) documentation
as the primary node.

In these instructions we assume:

- Your primary KDK instance is in a folder named `kdk`.
- Your secondary KDK instance lives in a parallel folder named `kdk-geo`.

If you use different folder names, modify the commands below as needed. To create the folder for the secondary instance, run the
following in the parent folder of the `kdk` folder:

```shell
git clone https://github.com/khulnasoft-lab/khulnasoft-development-kit.git kdk-geo
cd kdk-geo
```

#### Primary

Add the following to `kdk.yml` file on the primary node:

```yaml
---
geo:
  enabled: true
```

Though this setting normally indicates the node is a secondary, many scripts and `make` targets
assume they can run secondary-specific logic on any node. That is, rather than the scripts being
node-type aware, this ensures the primary can act "like a secondary" in some cases
such as when running tests.

#### Secondary

Add the following to the `kdk.yml` file to configure unique ports for the new instance so
that it can run alongside the primary:

```yaml
---
geo:
  enabled: true
  secondary: true
  node_name: kdk-geo
khulnasoft_pages:
  enabled: true
  port: 3011
tracer:
  jaeger:
    enabled: false
object_store:
  enabled: true
  port: 9001
port: 3001
webpack:
  port: 3809
```

Then run the following command:

```shell
# Assuming your primary KDK instance lives in parallel folders:
kdk install khulnasoft_repo=../kdk/gitlab
```

The `khulnasoft_repo` parameter is an optimization, but it is not
strictly required. It saves you time by performing a local `git clone`
instead of pulling from KhulnaSoft.com. In addition, a `git pull` in the
`gitlab` directory updates from your local primary Git repository.

After installation finishes, run the following commands:

```shell
# Run this on your primary instance folder: (../kdk)
kdk start

# Run this on your secondary instance folder: (../kdk-geo)
kdk start postgresql postgresql-geo
make geo-secondary-setup
```

#### Praefect on a Geo secondary

After you change the setting of `geo.secondary` in your KDK configuration, you must recreate the Praefect database. For more information, see the [Praefect documentation](../gitaly.md#praefect-on-a-geo-secondary).

### Database replication

For KhulnaSoft Geo, you need a primary/secondary database replication defined.
There are a few extra steps to follow.

### Prepare primary for replication

In your primary instance (`kdk`), prepare the database for
replication. This requires the PostgreSQL server to be running. You must start
the server, perform the change (with a `make` task), and then kill and restart
the server to apply the change:

```shell
# terminal window 1:
cd kdk
kdk start postgresql
make postgresql-geo-replication-primary
kdk restart postgresql
make postgresql-replication-primary-create-slot
kdk restart postgresql
```

#### Prepare secondary for replication

1. Remove the secondary PostgreSQL folder. This is done because you replicated the primary database to the secondary:

   ```shell
   # terminal window 2:
   cd kdk-geo
   kdk stop postgresql
   rm -r postgresql/data

1. Add a symbolic link to the primary instance's data folder:

   ```shell
   # From the kdk-geo folder:
   ln -s ../kdk/postgresql postgresql-primary

1. Initialize a secondary database and setup replication:

   ```shell
   # terminal window 2:
   make postgresql-geo-replication-secondary

### Copy database encryption key

The primary and the secondary nodes use the same secret key to encrypt and decrypt attributes in the database. To copy the secret from your primary to your secondary:

1. Open `kdk/gitlab/config/secrets.yml` with your editor of choice.
1. Copy the value of `development.db_key_base`.
1. Paste it into `kdk-geo/gitlab/config/secrets.yml`.

### Configure Geo nodes

#### Add a license that includes the Geo feature

1. Get a [test license](https://about.gitlab.com/handbook/support/workflows/test_env.html#testing-environment-license)
1. Upload the license on your local Geo primary at <http://kdk.test:3000/admin/license>

#### Add primary node

1. Add the primary node:

   ```shell
   cd kdk/gitlab

   bundle exec rake geo:set_primary_node
   ```

1. Restart Rails processes:

   ```shell
   kdk restart rails
   ```

#### Add secondary node

There isn't a convenient Rake task to add the secondary node because the relevant
data is on the secondary, but you can only write to the primary database. So you
must get the values from the secondary, and then manually add the node.

1. In a terminal, change to the `gitlab` directory of the secondary node:

   ```shell
   cd kdk-geo/gitlab
   ```

1. Output the secondary node's **Name** and **URL**:

   ```shell
   bundle exec rails runner 'puts "Name: #{GeoNode.current_node_name}"; puts "URL: #{GeoNode.current_node_url}"'
   ```

1. In your browser, go to the **primary** node's **Admin Area > Geo > Nodes** (`/admin/geo/nodes`).
1. Select **New node**.
1. To complete the **Name** and **URL** fields for the **secondary** node, use the values that you output in step 2.
1. Select **Save changes**.

![Adding a secondary node](../img/adding_a_secondary_node.png)

### Configure Unified URL

Unified URL is the recommended Geo configuration since KhulnaSoft 14.6, so it's valuable for Geo engineers to dogfood it locally.

#### Unified URL prerequisites

You must have two functioning Geo sites:

<!-- markdownlint-disable MD044 -->

- One primary site at `http://kdk.test:3000`
- One secondary read-only site at `http://kdk.test:3001`

<!-- markdownlint-enable MD044 -->

#### Minimal configuration to test Unified URL

You could set up a reverse proxy at port `3002` to forward requests to either site. But here we will show a minimal way to test Unified URL:

1. Choose one site to receive your requests to the Unified URL. In this example, we choose the secondary because it has the interesting behavior. When you visit the secondary site, it forwards your requests to the primary site when appropriate.
1. Set the primary's `geo_nodes` record's URL to be the exact same string as the secondary's URL. This unifies them in the DB. This change causes the secondary's API to tell Workhorse to enable proxying:

   ```shell
   bundle exec rails runner 'GeoNode.primary_node.update!(url: GeoNode.secondary_nodes.first.url, internal_url: GeoNode.primary_node.url)'
   ```

   In the above command, we also set the primary's `geo_nodes` record's Internal URL explicitly, since it is no longer the same URL. This is required for the secondary to make requests against the primary, and to forward requests to the primary.

   This command works given the prerequisites, but if your `url` or `internal_url` ever gets misconfigured, then open a Rails console and set them manually.

1. Optional. In your primary's `kdk.yml`, add:

   ```yaml
   gitlab:
     rails:
       port: 3001
   ```

   This is like setting `external_url` for KhulnaSoft Rails only. It makes the primary generate absolute URLs matching the Unified URL. One example of an absolute URL generated by the backend is the Git remote HTTP URL on a project page.

   You can still visit the primary directly, just as you can access any KhulnaSoft instance at a different URL than its external URL. However, you may find some edge cases. Using the same example above: Git remote URLs will always point to the Unified URL regardless of the URL you are visiting the primary at.

1. Comment out the `webpack` section in the secondary's `kdk.yml`, or set the `listen_address` and `port` to be the same as on the primary if you're not using the defaults.

   After a reconfigure, the Rails webpack configuration uses the connection details of the primary webpack.

   You no longer have to start `webpack` on the secondary site, which saves memory.

   However, there are still pages that are not proxied and might not load here, including the Geo replication details for projects and designs.
   If you wish to access and modify these pages in development, you should disable unified URLs for now.
