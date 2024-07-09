# AppRole for externalsecrets within the hostedcluster
resource "vault_policy" "this" {
  count  = var.deploy_vault_app_role ? 1 : 0
  name   = "${local.name}-vault-approle"
  policy = <<EOT
path "secret/data/kubernetes/${var.environment}-${var.project}/common/*" {
  capabilities = ["read"]
}
path "secret/data/kubernetes/${var.environment}-${var.project}/${var.cluster}/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_approle_auth_backend_role" "this" {
  count  = var.deploy_vault_app_role ? 1 : 0
  backend        = "approle"
  role_name      = "${local.name}-vault-approle"
  token_policies = [vault_policy.this[count.index].name]
}

resource "vault_approle_auth_backend_role_secret_id" "this" {
  count  = var.deploy_vault_app_role ? 1 : 0
  backend   = "approle"
  role_name = vault_approle_auth_backend_role.this[count.index].role_name
}

# Retrieve GitHub oauth credentials from vault
module "github_oauth_idp" {
  count  = var.github_oauth_enabled ? 1 : 0
  source = "git@github.com:3scale-ops/tf-vault-secret.git?ref=tags/0.1.3"
  path   = "kubernetes/${var.environment}-${var.project}/${var.cluster}/github-oauth-idp"
}
