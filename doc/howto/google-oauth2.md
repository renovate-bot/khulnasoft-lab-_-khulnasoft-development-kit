---
title: Google Oauth2 (GKE Cluster Integration, OAuth2 Login, etc)
---

## GCP Setup

Using GCP with KDK requires an OAuth client.

If you:

- Have access to the `gitlab-internal-153318` GCP project, you can use our
[shared OAuth client](https://console.cloud.google.com/apis/credentials/oauthclient/696404988091-a80933t1dpfu38khu8o4mfrt32pad0ij.apps.googleusercontent.com?project=gitlab-internal-153318).
- Don't have access to the shared project, use the following instructions to create your
own OAuth credentials:

  1. Go to [API & Services](https://console.cloud.google.com/apis/credentials).
  1. Click **+ CREATE CREDENTIALS > OAuth client ID**.
  1. Choose **Web application** as Application type.
  1. Fill the form with application name.
  1. Fill in following URLs in **Authorized redirect URIs**:
     - `http://localhost:3000/users/auth/google_oauth2/callback` # For Oauth2 Login`
     - `http://localhost:3000/-/google_api/auth/callback` # For GKE Cluster Integration`
  1. Click **Create**.
  1. Go to the entry. Copy Client ID and Client secret as described below.

## KDK Setup

From the KDK root directory, add the credentials to `kdk.yml`:

```yaml
omniauth:
  google_oauth2:
    client_id: <google-client-id>
    client_secret: <google-client-secret>
```

Then, in the KDK root directory run:

```shell
kdk reconfigure
```
