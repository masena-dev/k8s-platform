output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = module.kubernetes.kubeconfig
  sensitive   = true
}

output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.cluster_name
}

output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = module.kubernetes.cluster_id
}

output "cluster_host" {
  description = "Kubernetes API server host"
  value       = module.kubernetes.cluster_host
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = module.kubernetes.cluster_ca_certificate
  sensitive   = true
}

output "network_id" {
  description = "ID of the private network"
  value       = module.network.network_id
}

output "subnet_id" {
  description = "ID of the private subnet"
  value       = module.network.subnet_id
}

output "nodepool_id" {
  description = "ID of the node pool"
  value       = module.nodepool.nodepool_id
}

output "database_host" {
  description = "PostgreSQL server host"
  value       = var.database_provider == "managed" ? module.postgresql[0].host : null
}

output "database_port" {
  description = "PostgreSQL server port"
  value       = var.database_provider == "managed" ? module.postgresql[0].port : null
}

output "database_name" {
  description = "Name of the application database"
  value       = var.database_provider == "managed" ? module.postgresql[0].database_name : null
}

output "database_username" {
  description = "PostgreSQL username"
  value       = var.database_provider == "managed" ? module.postgresql[0].username : null
}

output "database_password" {
  description = "PostgreSQL password"
  value       = var.database_provider == "managed" ? module.postgresql[0].password : null
  sensitive   = true
}

output "object_storage_access_key" {
  description = "S3 access key for object storage"
  value       = var.enable_object_storage ? module.object_storage[0].access_key : null
  sensitive   = true
}

output "object_storage_secret_key" {
  description = "S3 secret key for object storage"
  value       = var.enable_object_storage ? module.object_storage[0].secret_key : null
  sensitive   = true
}

output "object_storage_endpoint" {
  description = "S3 endpoint for object storage"
  value       = var.enable_object_storage ? module.object_storage[0].endpoint : null
}

output "object_storage_region" {
  description = "S3 region (lowercase)"
  value       = var.enable_object_storage ? module.object_storage[0].region : null
}

output "object_storage_bucket_names" {
  description = "Map of logical to actual bucket names"
  value       = var.enable_object_storage ? module.object_storage[0].bucket_names : null
}
