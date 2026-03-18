resource "random_id" "nodepool_suffix" {
  byte_length = 4

  keepers = {
    flavor = var.flavor
  }
}

resource "ovh_cloud_project_kube_nodepool" "pool" {
  service_name   = var.project_id
  kube_id        = var.cluster_id
  name           = "${var.pool_name}-${random_id.nodepool_suffix.hex}"
  flavor_name    = var.flavor
  desired_nodes  = var.desired_nodes
  min_nodes      = var.min_nodes
  max_nodes      = var.max_nodes
  monthly_billed = false
  autoscale      = var.autoscale

  lifecycle {
    create_before_destroy = true
  }
}
