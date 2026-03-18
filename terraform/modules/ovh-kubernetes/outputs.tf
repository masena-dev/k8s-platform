output "cluster_id" {
  description = "ID of the Kubernetes cluster"
  value       = ovh_cloud_project_kube.cluster.id
}

output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = ovh_cloud_project_kube.cluster.kubeconfig
  sensitive   = true
}

output "cluster_host" {
  description = "Kubernetes API server host"
  value       = ovh_cloud_project_kube.cluster.url
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = base64decode(yamldecode(ovh_cloud_project_kube.cluster.kubeconfig)["clusters"][0]["cluster"]["certificate-authority-data"])
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate for authentication"
  value       = base64decode(yamldecode(ovh_cloud_project_kube.cluster.kubeconfig)["users"][0]["user"]["client-certificate-data"])
  sensitive   = true
}

output "client_key" {
  description = "Client key for authentication"
  value       = base64decode(yamldecode(ovh_cloud_project_kube.cluster.kubeconfig)["users"][0]["user"]["client-key-data"])
  sensitive   = true
}
