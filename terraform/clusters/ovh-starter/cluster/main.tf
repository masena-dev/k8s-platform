locals {
  database_ip_restrictions = length(var.database_ip_restrictions) > 0 ? var.database_ip_restrictions : [
    {
      ip          = var.subnet_cidr
      description = "Allow cluster private subnet"
    }
  ]
}

module "platform" {
  source = "../../../platforms/ovh"

  project_id   = var.openstack_tenant_name
  cluster_name = var.cluster_name
  domain       = var.domain
  region       = var.region
  subnet_cidr  = var.subnet_cidr

  node_flavor   = var.node_flavor
  desired_nodes = var.desired_nodes
  min_nodes     = var.min_nodes
  max_nodes     = var.max_nodes
  autoscale     = var.autoscale

  enable_oidc          = var.enable_oidc
  oidc_client_id       = var.oidc_client_id
  oidc_client_secret   = var.oidc_client_secret
  oidc_issuer_url      = var.oidc_issuer_url
  oidc_username_claim  = var.oidc_username_claim
  oidc_groups_claim    = var.oidc_groups_claim
  oidc_username_prefix = var.oidc_username_prefix

  database_provider        = var.database_provider
  database_region          = var.database_region
  database_plan            = var.database_plan
  database_flavor          = var.database_flavor
  database_name            = var.database_name
  database_username        = var.database_username
  database_ip_restrictions = local.database_ip_restrictions
  environment              = var.environment

  enable_object_storage = var.enable_object_storage
  storage_region        = var.storage_region

  api_server_ip_restrictions = var.api_server_ip_restrictions
}
