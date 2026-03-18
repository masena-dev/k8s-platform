resource "ovh_cloud_project_kube" "cluster" {
  service_name = var.project_id
  name         = var.cluster_name
  region       = var.region

  private_network_id = var.openstack_network_id

  private_network_configuration {
    default_vrack_gateway              = ""
    private_network_routing_as_default = true
  }
}

resource "ovh_cloud_project_kube_oidc" "oidc" {
  count = var.enable_oidc ? 1 : 0

  service_name = var.project_id
  kube_id      = ovh_cloud_project_kube.cluster.id

  client_id  = var.oidc_client_id
  issuer_url = var.oidc_issuer_url

  oidc_username_claim  = var.oidc_username_claim
  oidc_username_prefix = var.oidc_username_prefix
  oidc_groups_claim    = var.oidc_groups_claim
}

resource "ovh_cloud_project_kube_iprestrictions" "restrictions" {
  count = length(var.api_server_ip_restrictions) > 0 ? 1 : 0

  service_name = var.project_id
  kube_id      = ovh_cloud_project_kube.cluster.id
  ips          = var.api_server_ip_restrictions
}
