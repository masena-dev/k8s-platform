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

# Cloud-specific outputs

output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = module.platform.cluster_id
}

output "network_id" {
  description = "ID of the private network"
  value       = module.platform.network_id
}

output "subnet_id" {
  description = "ID of the private subnet"
  value       = module.platform.subnet_id
}

output "nodepool_id" {
  description = "ID of the node pool"
  value       = module.platform.nodepool_id
}

# Optional database outputs

output "database_host" {
  description = "PostgreSQL server host"
  value       = module.platform.database_host
}

output "database_port" {
  description = "PostgreSQL server port"
  value       = module.platform.database_port
}

output "database_name" {
  description = "Name of the application database"
  value       = module.platform.database_name
}

output "database_username" {
  description = "PostgreSQL username"
  value       = module.platform.database_username
}

output "database_password" {
  description = "PostgreSQL password"
  value       = module.platform.database_password
  sensitive   = true
}

output "object_storage_access_key" {
  description = "S3 access key for object storage"
  value       = module.platform.object_storage_access_key
  sensitive   = true
}

output "object_storage_secret_key" {
  description = "S3 secret key for object storage"
  value       = module.platform.object_storage_secret_key
  sensitive   = true
}

output "object_storage_endpoint" {
  description = "S3 endpoint for object storage"
  value       = module.platform.object_storage_endpoint
}

output "object_storage_region" {
  description = "S3 region (lowercase)"
  value       = module.platform.object_storage_region
}

output "object_storage_bucket_names" {
  description = "Map of logical to actual bucket names"
  value       = module.platform.object_storage_bucket_names
}
