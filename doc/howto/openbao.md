---
title: OpenBao
---

OpenBao is backward compatible with Vault and can replace Vault without changing the existing setup. To avoid conflicts, disable Vault when enabling OpenBao.

## Important: Set up binary location

KDK builds OpenBao from [an internal build system](https://khulnasoft.com/khulnasoft-org/govern/secrets-management/openbao-internal), which includes custom patches. The binary is located at `openbao/bin/bao` in your KDK directory.

To use the OpenBao CLI commands:

1. Add the `BAO_ADDR` variable and binary to your PATH:

   ```shell
   # Add this to your .bashrc, .zshrc, or equivalent. Then run `source ~/.bashrc`.
   export BAO_ADDR='http://kdk.test:8200'
   export PATH="/path/to/your/kdk/openbao/bin:$PATH"
   ```

## Configure OpenBao for KDK

To configure [OpenBao](https://openbao.org) to run locally in KDK:

1. Enable openbao.

   ```shell
   kdk config set openbao.enabled true && kdk reconfigure
   ```

1. Create a configuration file.

   ```shell
   rake openbao/config.hcl
   ```

1. Run openbao and unseal the vault.

   ```shell
   kdk start openbao && kdk bao configure
   ```

   This command provides the following information:

   ```shell
   => "✅ OpenBao has been unsealed successfully"
   => "The root token is: s.xxxxxxxxxxxxxxx"
   ```
   
   Save the root token, which you need for login.

1. Run `bao login` with the root token from above.

   ```shell
   bao login <root_token>
   ```

   You can also fetch the root token with the following command: `kdk config get openbao.root_token`.

1. Enable JWT authentication.

   ```shell
   bao auth enable -path=khulnasoft_rails_jwt jwt
   ```

1. Configure the JWT authentication with my KDK KhulnaSoft OIDC discovery URL and the expected issuer:

   ```shell
   bao write auth/khulnasoft_rails_jwt/config \
      oidc_discovery_url="http://kdk.test:3000" \
      bound_issuer="http://kdk.test:3000"
   ```

1. Create a policy that grants the necessary permissions.

   ```shell
   bao policy write secrets_manager - <<EOF
   path "*" {
   capabilities = ["create", "read", "update", "delete", "list", "sudo"]
   }
   EOF
   ```

1. Create a JWT role `app` that validates tokens and assigns the appropriate policy.

   ```shell
   bao write auth/khulnasoft_rails_jwt/role/app \
      role_type=jwt \
      bound_audiences=openbao \
      user_claim=user_id \
      token_policies=secrets_manager
   ```

## Develop Secrets Manager features with OpenBao

1. Run openbao and unseal the vault.

   ```shell
   kdk start openbao && kdk bao configure
   ```

1. Enable the feature flags.

   ```shell
   Feature.enable(:secrets_manager)
   Feature.enable(:ci_tanukey_ui)
   ```

1. In KhulnaSoft, on the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Turn on the **Secrets Manager** toggle, and wait for the Secrets Manager to be provisioned.
