variable "cluster_name" {
  description = "Cluster name — used for resource naming and ArgoCD app-of-apps identity."
  type        = string
}

# --- Terraform Remote State ---

variable "state_bucket" {
  description = "S3 bucket for Terraform remote state."
  type        = string

  validation {
    condition     = length(var.state_bucket) > 0
    error_message = "state_bucket must be set (e.g. via TF_VAR_state_bucket env var)."
  }
}

variable "state_region" {
  description = "AWS region of the S3 state bucket."
  type        = string
  default     = "eu-west-1"
}

variable "state_endpoint" {
  description = "S3 endpoint for the Terraform state bucket. Defaults to OVH S3 endpoint derived from state_region."
  type        = string
  default     = ""
}

# --- ArgoCD ---

variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart"
  type        = string
  default     = "9.4.1"
}

variable "argocd_repo_url" {
  description = "Git repository URL for ArgoCD to watch"
  type        = string
}

variable "argocd_target_revision" {
  description = "Git branch or tag for ArgoCD to track"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub token for private repo access (leave empty for public repos)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ghcr_username" {
  description = "GitHub username for pulling private images from GHCR. Leave empty to skip."
  type        = string
  default     = ""
}

variable "ghcr_token" {
  description = "GitHub PAT with read:packages scope for GHCR pull access. Falls back to github_token if empty."
  type        = string
  sensitive   = true
  default     = ""
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
  default     = "ops@your-company.com"
}

# --- Secret Zero (ESO + 1Password SDK bootstrap) ---

variable "enable_onepassword_bootstrap" {
  description = "Create external-secrets namespace and bootstrap secret for 1Password SDK auth."
  type        = bool
  default     = true
}

variable "onepassword_service_account_token" {
  description = "1Password service account token for ESO SDK authentication."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = !var.enable_onepassword_bootstrap || var.onepassword_service_account_token != ""
    error_message = "onepassword_service_account_token must be set when enable_onepassword_bootstrap is true."
  }
}

# --- OIDC RBAC ---

variable "oidc_viewers" {
  description = "OIDC user emails to grant view (read-only) cluster access"
  type        = list(string)
  default     = []
}

variable "oidc_admins" {
  description = "OIDC user emails to grant cluster-admin access"
  type        = list(string)
  default     = []
}

variable "oidc_username_prefix" {
  description = "OIDC username prefix (must match cluster OIDC config)"
  type        = string
  default     = "oidc:"
}

# --- OIDC / OAuth (generic, provider-agnostic) ---

variable "oidc_issuer_url" {
  description = "OIDC issuer URL (e.g. https://accounts.google.com, https://login.microsoftonline.com/{tenant}/v2.0)"
  type        = string
  default     = "https://accounts.google.com"
}

variable "grafana_oauth_client_id" {
  description = "OAuth client ID for Grafana SSO. Leave empty to skip."
  type        = string
  default     = ""
}

variable "grafana_oauth_client_secret" {
  description = "OAuth client secret for Grafana SSO."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.grafana_oauth_client_id == "" || var.grafana_oauth_client_secret != ""
    error_message = "grafana_oauth_client_secret is required when grafana_oauth_client_id is set."
  }
}

variable "oidc_allowed_domains" {
  description = "Comma-separated email domains allowed to log in via OIDC/OAuth. Enforced by Grafana; ArgoCD access is controlled via RBAC."
  type        = string
  default     = ""

  validation {
    condition     = var.grafana_oauth_client_id == "" || var.oidc_allowed_domains != ""
    error_message = "oidc_allowed_domains is required when Grafana OAuth is enabled. An empty value would allow any authenticated user."
  }
}

variable "grafana_oauth_scopes" {
  description = "OAuth scopes to request."
  type        = string
  default     = "openid email profile"
}

variable "grafana_oauth_auth_url" {
  description = "OAuth authorization endpoint for Grafana."
  type        = string
  default     = "https://accounts.google.com/o/oauth2/v2/auth"
}

variable "grafana_oauth_token_url" {
  description = "OAuth token endpoint for Grafana."
  type        = string
  default     = "https://oauth2.googleapis.com/token"
}

variable "grafana_oauth_api_url" {
  description = "OAuth userinfo endpoint for Grafana."
  type        = string
  default     = "https://openidconnect.googleapis.com/v1/userinfo"
}

variable "argocd_oidc_client_id" {
  description = "OIDC client ID for ArgoCD SSO. Leave empty to skip."
  type        = string
  default     = ""
}

variable "argocd_oidc_client_secret" {
  description = "OIDC client secret for ArgoCD SSO."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.argocd_oidc_client_id == "" || var.argocd_oidc_client_secret != ""
    error_message = "argocd_oidc_client_secret is required when argocd_oidc_client_id is set."
  }
}

variable "kubectl_oidc_client_id" {
  description = "OIDC client ID for kubectl/kubelogin. Leave empty to skip kubeconfig generation."
  type        = string
  default     = ""
}

variable "kubectl_oidc_client_secret" {
  description = "OIDC client secret for kubectl/kubelogin (some providers require this)."
  type        = string
  sensitive   = true
  default     = ""
}

# --- Cloud Provider ---

variable "cloud_provider" {
  description = "Cloud provider for platform overlay (ovh, hetzner)"
  type        = string
  default     = "ovh"

  validation {
    condition     = contains(["ovh", "hetzner"], var.cloud_provider)
    error_message = "cloud_provider must be one of: ovh, hetzner"
  }
}

# --- Bootstrap Secrets ---

variable "grafana_admin_password" {
  description = "Grafana admin password. Leave empty to auto-generate a 24-character password."
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for external-dns (DNS automation)."
  type        = string
  sensitive   = true

  validation {
    condition     = var.cloudflare_api_token != ""
    error_message = "cloudflare_api_token must be set (Cloudflare API token with Zone:DNS:Edit permissions)."
  }
}

# --- Monitoring basicAuth ---

variable "monitoring_basic_auth_username" {
  description = "Username for monitoring basicAuth (Prometheus/AlertManager). Defaults to 'admin'."
  type        = string
  default     = "admin"
}

variable "monitoring_basic_auth_password" {
  description = "Password for monitoring basicAuth. Leave empty to auto-generate a 32-character password."
  type        = string
  sensitive   = true
  default     = ""
}

# --- 1Password Dual-Vault ---

variable "onepassword_infra_vault_id" {
  description = "1Password vault UUID used by Terraform to write infrastructure items (grafana-*, cloudflare-dns-*). Leave empty to skip writing items."
  type        = string
  default     = ""
}

variable "onepassword_infra_vault" {
  description = "1Password vault name used by ESO's 1Password SDK ClusterSecretStore (e.g. -infra). If empty, Terraform will look up the name from onepassword_infra_vault_id."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_onepassword_bootstrap || var.onepassword_infra_vault != "" || var.onepassword_infra_vault_id != ""
    error_message = "Either onepassword_infra_vault (name) or onepassword_infra_vault_id (UUID) must be set when enable_onepassword_bootstrap is true."
  }
}

variable "onepassword_team_logins_vault_id" {
  description = "1Password vault ID for team browser logins. Leave empty to skip."
  type        = string
  default     = ""
}

variable "domain" {
  description = "Base domain for cluster URLs. Used to populate the URL field on 1Password login items (ArgoCD/Grafana) and by the GitOps layer for demo ingress hostnames."
  type        = string

  validation {
    condition     = var.domain != ""
    error_message = "domain must be set (e.g. example.com)."
  }
}

variable "cnpg_enabled" {
  description = "Enable CloudNativePG operator and PostgreSQL cluster"
  type        = bool
  default     = false
}

variable "cnpg_namespace" {
  description = "Namespace where the CNPG cluster is deployed."
  type        = string
  default     = "database"
}

variable "cnpg_cluster_name" {
  description = "CNPG cluster name used for service discovery."
  type        = string
  default     = "postgres"
}

variable "cnpg_pooler_enabled" {
  description = "Whether the CNPG chart exposes the application through a PgBouncer pooler service."
  type        = bool
  default     = true
}

variable "cnpg_instances" {
  description = "Number of CNPG cluster instances. Must match cluster.instances in the CNPG Helm values. Controls whether DATABASE_READ_URL uses the read pooler (instances > 1) or the all-instances service (instances = 1)."
  type        = number
  default     = 1
}

variable "cnpg_database_name" {
  description = "Application database name bootstrapped by the CNPG cluster."
  type        = string
  default     = "app"
}

variable "cnpg_database_user" {
  description = "Application database user bootstrapped by the CNPG cluster."
  type        = string
  default     = "app"
}
