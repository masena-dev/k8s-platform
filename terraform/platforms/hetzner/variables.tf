# --- Authentication ---

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

# --- SSH keys ---

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

variable "region" {
  description = "Hetzner Cloud location (fsn1, nbg1, hel1)"
  type        = string
  default     = "nbg1"
}

variable "network_region" {
  description = "Hetzner Cloud network region (eu-central covers fsn1, nbg1, hel1)"
  type        = string
  default     = "eu-central"
}

variable "dns_servers" {
  description = "DNS resolvers configured on Hetzner nodes. Public resolvers avoid stale provider-local caches that can block cert-manager HTTP-01 self-checks after external-dns creates records."
  type        = list(string)
  default     = ["1.1.1.1", "1.0.0.1", "8.8.8.8"]
}

variable "k3s_channel" {
  description = "K3s release channel (e.g., v1.31)"
  type        = string
  default     = "v1.31"
}

# --- Control plane ---

variable "control_plane_server_type" {
  description = "Server type for control plane nodes (cax21 = 4 ARM vCPU, 8 GB — cost-effective default)"
  type        = string
  default     = "cax21"
}

variable "control_plane_count" {
  description = "Number of control plane nodes (use 3 for HA)"
  type        = number
  default     = 3
}

# --- Worker nodes ---

variable "server_type" {
  description = "Server type for worker nodes (cax21 = 4 ARM vCPU, 8 GB — cost-effective default)"
  type        = string
  default     = "cax21"
}

variable "desired_nodes" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

# --- Storage nodes (optional) ---

variable "enable_storage_nodes" {
  description = "Enable dedicated Longhorn storage nodes with labels and taints"
  type        = bool
  default     = false
}

variable "storage_server_type" {
  description = "Server type for storage nodes (cax41 = 16 vCPU ARM, 32 GB, 320 GB NVMe, ~€24.49/mo)"
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

# --- Firewall ---

variable "extra_firewall_rules" {
  description = "Additional outbound firewall rules for the Hetzner cluster. By default, only DNS, HTTP/HTTPS, NTP, and ICMP are allowed."
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
