variable "project_id" {
  description = "OVH Public Cloud project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "region" {
  description = "OVH region for the cluster"
  type        = string
  default     = "DE1"
}

variable "openstack_network_id" {
  description = "ID of the OpenStack private network"
  type        = string
}

# --- OIDC Configuration ---

variable "enable_oidc" {
  description = "Enable OIDC authentication for the cluster"
  type        = bool
  default     = true
}

variable "oidc_client_id" {
  description = "OIDC client ID"
  type        = string
  default     = ""
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL"
  type        = string
  default     = "https://accounts.google.com"
}

variable "oidc_username_claim" {
  description = "OIDC username claim"
  type        = string
  default     = "email"
}

variable "oidc_groups_claim" {
  description = "OIDC groups claim(s)"
  type        = list(string)
  default     = ["groups"]
}

variable "oidc_username_prefix" {
  description = "OIDC username prefix"
  type        = string
  default     = "oidc:"
}

# --- API Server IP Restrictions ---

variable "api_server_ip_restrictions" {
  description = "List of CIDR blocks allowed to access the Kubernetes API server. Empty list means unrestricted."
  type        = list(string)
  default     = []
}
