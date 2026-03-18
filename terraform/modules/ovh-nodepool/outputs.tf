output "nodepool_id" {
  description = "ID of the node pool"
  value       = ovh_cloud_project_kube_nodepool.pool.id
}

output "nodepool_name" {
  description = "Name of the node pool"
  value       = ovh_cloud_project_kube_nodepool.pool.name
}
