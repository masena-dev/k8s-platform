# --- Required outputs (output contract) ---

output "kubeconfig" {
  description = "Full kubeconfig YAML for the cluster"
  value       = module.kube-hetzner.kubeconfig
  sensitive   = true
}

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.cluster_name
}

output "cluster_host" {
  description = "Kubernetes API server host"
  value       = module.kube-hetzner.kubeconfig_data.host
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64-decoded)"
  value       = module.kube-hetzner.kubeconfig_data.cluster_ca_certificate
  sensitive   = true
}

# --- Cloud-specific outputs ---

output "kubeconfig_data" {
  description = "Structured kubeconfig data (host, CA, client cert/key)"
  value       = module.kube-hetzner.kubeconfig_data
  sensitive   = true
}

# --- Optional outputs (not provisioned on Hetzner) ---

output "database_host" {
  description = "Database server host (not provisioned)"
  value       = null
}

output "database_port" {
  description = "Database server port (not provisioned)"
  value       = null
}

output "database_name" {
  description = "Database name (not provisioned)"
  value       = null
}

output "database_username" {
  description = "Database username (not provisioned)"
  value       = null
}

output "database_password" {
  description = "Database password (not provisioned)"
  value       = null
  sensitive   = true
}
