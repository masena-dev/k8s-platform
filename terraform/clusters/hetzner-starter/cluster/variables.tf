# --- Hetzner Provider ---

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

# --- SSH Keys ---

variable "ssh_public_key" {
  description = "SSH public key content or a path to the public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
  description = "SSH private key content or a path to the private key file"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "hcloud_ssh_key_id" {
  description = "Existing Hetzner Cloud SSH key ID to reuse. Leave null to create a new key from ssh_public_key."
  type        = string
  default     = null
}

# --- Cluster ---

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "domain" {
  description = "Base domain used to derive globally-unique object storage bucket names when Hetzner object storage is enabled."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_object_storage || var.domain != ""
    error_message = "domain must be set when enable_object_storage is true (e.g. example.com)."
  }
}

variable "region" {
  description = "Hetzner Cloud location (fsn1, nbg1, hel1)"
  type        = string
  default     = "nbg1"
}

variable "network_region" {
  description = "Hetzner Cloud network region"
  type        = string
  default     = "eu-central"
}

variable "dns_servers" {
  description = "DNS resolvers configured on Hetzner nodes. Defaults use public resolvers so new Cloudflare records are visible to cert-manager self-checks during bootstrap."
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1", "8.8.8.8"]
}

variable "k3s_channel" {
  description = "K3s release channel"
  type        = string
  default     = "v1.31"
}

# --- Control Plane ---

variable "control_plane_server_type" {
  description = "Server type for control plane nodes"
  type        = string
  default     = "cpx22"
}

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 3
}

# --- Worker Nodes ---

variable "server_type" {
  description = "Server type for worker nodes"
  type        = string
  default     = "cpx32"
}

variable "desired_nodes" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

# --- Storage Nodes (optional) ---

variable "enable_storage_nodes" {
  description = "Enable dedicated Longhorn storage nodes with labels and taints"
  type        = bool
  default     = false
}

variable "storage_server_type" {
  description = "Server type for storage nodes (cax41 = 16 vCPU ARM, 32 GB, 320 GB NVMe)"
  type        = string
  default     = "cax41"
}

variable "storage_node_count" {
  description = "Number of dedicated storage nodes (minimum 2 for replication)"
  type        = number
  default     = 2
}

# --- OIDC Configuration ---

variable "enable_oidc" {
  description = "Enable OIDC authentication for the cluster"
  type        = bool
  default     = false
}

variable "oidc_client_id" {
  description = "OIDC client ID for Google OAuth"
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
  description = "OIDC groups claim"
  type        = string
  default     = "groups"
}

variable "oidc_username_prefix" {
  description = "OIDC username prefix"
  type        = string
  default     = "oidc:"
}

# --- Object Storage (Hetzner S3-compatible) ---

variable "enable_object_storage" {
  description = "Provision S3-compatible object storage buckets (Hetzner Object Storage)."
  type        = bool
  default     = false
}

variable "object_storage_access_key" {
  description = "Access key for Hetzner Object Storage (generated in Hetzner Cloud Console)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "object_storage_secret_key" {
  description = "Secret key for Hetzner Object Storage (generated in Hetzner Cloud Console)."
  type        = string
  sensitive   = true
  default     = ""
}

# --- Firewall ---

variable "extra_firewall_rules" {
  description = "Additional outbound firewall rules. See docs/customization.md for examples."
  type = list(object({
    direction       = string
    port            = string
    protocol        = string
    source_ips      = list(string)
    destination_ips = list(string)
    description     = string
  }))
  default = []
}
