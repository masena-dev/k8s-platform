module "platform" {
  source = "../../../platforms/hetzner"

  providers = {
    hcloud = hcloud
  }

  hcloud_token      = var.hcloud_token
  ssh_public_key    = var.ssh_public_key
  ssh_private_key   = var.ssh_private_key
  hcloud_ssh_key_id = var.hcloud_ssh_key_id
  cluster_name      = var.cluster_name
  region            = var.region
  network_region    = var.network_region
  dns_servers       = var.dns_servers
  k3s_channel       = var.k3s_channel

  control_plane_server_type = var.control_plane_server_type
  control_plane_count       = var.control_plane_count
  server_type               = var.server_type
  desired_nodes             = var.desired_nodes

  enable_storage_nodes = var.enable_storage_nodes
  storage_server_type  = var.storage_server_type
  storage_node_count   = var.storage_node_count

  enable_oidc          = var.enable_oidc
  oidc_client_id       = var.oidc_client_id
  oidc_issuer_url      = var.oidc_issuer_url
  oidc_username_claim  = var.oidc_username_claim
  oidc_groups_claim    = var.oidc_groups_claim
  oidc_username_prefix = var.oidc_username_prefix

  extra_firewall_rules = var.extra_firewall_rules
}

# --- Object Storage (S3-compatible buckets for Loki, backups, etc.) ---

locals {
  object_storage_bucket_prefix = "${replace(var.domain, ".", "-")}-${var.cluster_name}"
}

module "object_storage" {
  count  = var.enable_object_storage ? 1 : 0
  source = "../../../modules/s3-object-storage"

  providers = {
    aws = aws.hetzner_s3
  }

  # Wait until kube-hetzner finishes successfully before creating buckets.
  # Otherwise a failed cluster bootstrap can orphan globally unique bucket
  # names and force the next apply into BucketAlreadyExists errors.
  depends_on = [module.platform]

  bucket_prefix = local.object_storage_bucket_prefix
  bucket_names  = ["loki-chunks", "loki-ruler", "cnpg-backups"]
}
