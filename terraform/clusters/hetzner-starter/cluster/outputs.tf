# Re-export the output contract from the platform module

output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = module.platform.kubeconfig
  sensitive   = true
}

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.platform.cluster_name
}

output "cluster_host" {
  description = "Kubernetes API server host"
  value       = module.platform.cluster_host
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = module.platform.cluster_ca_certificate
  sensitive   = true
}

# Optional database outputs

output "database_host" {
  description = "Database server host (not provisioned)"
  value       = module.platform.database_host
}

output "database_port" {
  description = "Database server port (not provisioned)"
  value       = module.platform.database_port
}

output "database_name" {
  description = "Database name (not provisioned)"
  value       = module.platform.database_name
}

output "database_username" {
  description = "Database username (not provisioned)"
  value       = module.platform.database_username
}

output "database_password" {
  description = "Database password (not provisioned)"
  value       = module.platform.database_password
  sensitive   = true
}

# --- Object Storage outputs ---

output "object_storage_access_key" {
  description = "Object storage access key (passthrough for addons stage)"
  value       = var.enable_object_storage ? var.object_storage_access_key : null
  sensitive   = true
}

output "object_storage_secret_key" {
  description = "Object storage secret key (passthrough for addons stage)"
  value       = var.enable_object_storage ? var.object_storage_secret_key : null
  sensitive   = true
}

output "object_storage_endpoint" {
  description = "Object storage S3 endpoint"
  value       = var.enable_object_storage ? "https://${var.region}.your-objectstorage.com" : null
}

output "object_storage_region" {
  description = "Object storage region (must match the Hetzner Object Storage endpoint location, e.g. fsn1)"
  value       = var.enable_object_storage ? var.region : null
}

output "object_storage_bucket_names" {
  description = "Map of logical bucket name to actual bucket name"
  value       = var.enable_object_storage ? module.object_storage[0].bucket_names : null
}
