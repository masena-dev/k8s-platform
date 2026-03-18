output "argocd_admin_password" {
  description = "ArgoCD admin password (use with username 'admin')"
  value       = module.argocd.argocd_admin_password
  sensitive   = true
}

output "argocd_url" {
  description = "Instructions to access ArgoCD UI"
  value       = "Access via: kubectl port-forward svc/argocd-server -n argocd 8080:443"
}

output "grafana_admin_password" {
  description = "Grafana admin password (use with username 'admin')"
  value       = local.grafana_password
  sensitive   = true
}
