variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart"
  type        = string
  default     = "9.4.1"
}

variable "repo_url" {
  description = "Git repository URL for ArgoCD to watch"
  type        = string
}

variable "target_revision" {
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

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
  default     = "ops@your-company.com"
}

variable "cloud_provider" {
  description = "Cloud provider for platform overlay (ovh, hetzner)"
  type        = string
  default     = "ovh"

  validation {
    condition     = contains(["ovh", "hetzner"], var.cloud_provider)
    error_message = "cloud_provider must be one of: ovh, hetzner"
  }
}

variable "cluster_name" {
  description = "Cluster name, used for per-cluster GitOps overlay path"
  type        = string
  default     = ""
}

variable "onepassword_vault_id" {
  description = "1Password vault name for the ESO ClusterSecretStore (ESO 1Password SDK store is per-vault)"
  type        = string
  default     = ""
}

variable "onepassword_grafana_item_uuid" {
  description = "Optional: 1Password item UUID for grafana-* bootstrap secret lookup (avoids ambiguity when multiple items share the same title)."
  type        = string
  default     = ""
}

variable "onepassword_cloudflare_item_uuid" {
  description = "Optional: 1Password item UUID for cloudflare-dns-* bootstrap secret lookup (avoids ambiguity when multiple items share the same title)."
  type        = string
  default     = ""
}

variable "onepassword_grafana_oauth_item_uuid" {
  description = "Optional: 1Password item UUID for grafana-oidc-* bootstrap secret lookup."
  type        = string
  default     = ""
}

variable "onepassword_argocd_oidc_item_uuid" {
  description = "Optional: 1Password item UUID for argocd-oidc-* bootstrap secret lookup."
  type        = string
  default     = ""
}

variable "domain" {
  description = "Base domain for cluster URLs (used by the GitOps layer for ingress hostnames). Must match your Cloudflare zone, e.g. example.com."
  type        = string

  validation {
    condition     = var.domain != ""
    error_message = "domain must be set (e.g. example.com)."
  }
}

variable "loki_bucket_chunks" {
  description = "Loki chunks bucket name. Set by Terraform from the cluster stage when OVH Object Storage is enabled."
  type        = string
  default     = ""
}

variable "loki_bucket_ruler" {
  description = "Loki ruler bucket name. Set by Terraform from the cluster stage when OVH Object Storage is enabled."
  type        = string
  default     = ""
}

variable "cnpg_backup_bucket_name" {
  description = "CNPG backup bucket name. Set by Terraform from the cluster stage when object storage is provisioned."
  type        = string
  default     = ""
}

variable "object_storage_endpoint" {
  description = "S3 endpoint URL for platform object storage. Set by Terraform from the cluster stage when object storage is provisioned."
  type        = string
  default     = ""
}

variable "object_storage_region" {
  description = "S3 region/location for platform object storage. Set by Terraform from the cluster stage when object storage is provisioned."
  type        = string
  default     = ""
}

variable "onepassword_monitoring_auth_item_uuid" {
  description = "Optional: 1Password item UUID for monitoring-basic-auth-* bootstrap secret lookup."
  type        = string
  default     = ""
}

variable "enable_argocd_oidc" {
  description = "Enable ArgoCD OIDC configuration during initial Helm bootstrap."
  type        = bool
  default     = false
}

variable "argocd_oidc_client_id" {
  description = "OIDC client ID for ArgoCD SSO."
  type        = string
  default     = ""
}

variable "argocd_oidc_client_secret" {
  description = "OIDC client secret for ArgoCD SSO. Seeded into argocd-oidc-secret at bootstrap."
  type        = string
  sensitive   = true
  default     = ""
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL used by ArgoCD."
  type        = string
  default     = "https://accounts.google.com"
}

variable "enable_grafana_oauth" {
  description = "Enable Grafana generic OAuth configuration in the root Application."
  type        = bool
  default     = false
}

variable "oidc_allowed_domains" {
  description = "Comma-separated email domains allowed to log in via OIDC/OAuth. Enforced by Grafana; ArgoCD access is controlled via RBAC."
  type        = string
  default     = ""
}

variable "grafana_oauth_auth_url" {
  description = "OAuth authorization endpoint for Grafana generic OAuth."
  type        = string
  default     = "https://accounts.google.com/o/oauth2/v2/auth"
}

variable "grafana_oauth_token_url" {
  description = "OAuth token endpoint for Grafana generic OAuth."
  type        = string
  default     = "https://oauth2.googleapis.com/token"
}

variable "grafana_oauth_api_url" {
  description = "OAuth userinfo endpoint for Grafana generic OAuth."
  type        = string
  default     = "https://openidconnect.googleapis.com/v1/userinfo"
}

variable "grafana_oauth_scopes" {
  description = "OAuth scopes requested by Grafana generic OAuth."
  type        = string
  default     = "openid email profile"
}

variable "cnpg_enabled" {
  description = "Enable CloudNativePG operator and PostgreSQL cluster"
  type        = bool
  default     = false
}
