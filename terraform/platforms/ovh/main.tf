module "network" {
  source = "../../modules/ovh-network"

  network_name = "${var.cluster_name}-network"
  region       = var.region
  subnet_cidr  = var.subnet_cidr
}

module "kubernetes" {
  source = "../../modules/ovh-kubernetes"

  project_id           = var.project_id
  cluster_name         = var.cluster_name
  region               = var.region
  openstack_network_id = module.network.network_id

  enable_oidc          = var.enable_oidc
  oidc_client_id       = var.oidc_client_id
  oidc_issuer_url      = var.oidc_issuer_url
  oidc_username_claim  = var.oidc_username_claim
  oidc_groups_claim    = var.oidc_groups_claim
  oidc_username_prefix = var.oidc_username_prefix

  api_server_ip_restrictions = var.api_server_ip_restrictions
}

module "nodepool" {
  source = "../../modules/ovh-nodepool"

  project_id    = var.project_id
  cluster_id    = module.kubernetes.cluster_id
  pool_name     = "default"
  flavor        = var.node_flavor
  desired_nodes = var.desired_nodes
  min_nodes     = var.min_nodes
  max_nodes     = var.max_nodes
  autoscale     = var.autoscale
}

module "postgresql" {
  count  = var.database_provider == "managed" ? 1 : 0
  source = "../../modules/ovh-postgresql"

  project_id        = var.project_id
  network_id        = module.network.network_id
  subnet_id         = module.network.subnet_id
  region            = var.database_region != "" ? var.database_region : local.storage_region_default
  plan              = var.database_plan
  flavor            = var.database_flavor
  database_name     = var.database_name
  database_username = var.database_username
  ip_restrictions   = var.database_ip_restrictions
  environment       = var.environment
}

locals {
  # OVH OpenStack regions are AZ-specific (e.g. GRA9, SBG5, DE1). Object Storage
  # regions are the base codes (e.g. GRA, SBG, DE). If the caller doesn't
  # override storage_region, derive a sane default.
  storage_region_default = replace(var.region, "/[0-9].*$/", "")
}

module "object_storage" {
  count  = var.enable_object_storage ? 1 : 0
  source = "../../modules/ovh-object-storage"

  project_id    = var.project_id
  cluster_name  = var.cluster_name
  bucket_prefix = var.domain != "" ? "${var.domain}-${var.cluster_name}" : var.cluster_name
  region        = var.storage_region != "" ? var.storage_region : local.storage_region_default
}
