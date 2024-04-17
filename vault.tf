# AppRole for externalsecrets within the hostedcluster
resource "vault_policy" "this" {
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
  backend        = "approle"
  role_name      = "${local.name}-vault-approle"
  token_policies = [vault_policy.this.name]
}

resource "vault_approle_auth_backend_role_secret_id" "this" {
  backend   = "approle"
  role_name = vault_approle_auth_backend_role.this.role_name
}

# Retrieve GitHub oauth credentials from vault
module "github_oauth_idp" {
  count  = var.github_oauth_enabled ? 1 : 0
  source = "git@github.com:3scale-ops/tf-vault-secret.git?ref=tags/0.1.3"
  path   = "kubernetes/${var.environment}-${var.project}/${var.cluster}/github-oauth-idp"
}
