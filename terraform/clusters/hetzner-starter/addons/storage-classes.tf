# Cloud-portable storage class aliases for Hetzner
#
# These provide a cloud-agnostic interface that maps to Hetzner-specific storage:
# - fast-rwo      → longhorn (local NVMe, ~5000+ IOPS)
# - standard-rwo  → hcloud-volumes (network, ~1500 IOPS)
#
# On other clouds, the same aliases map to native storage:
# - AWS: fast-rwo → gp3 with provisioned IOPS, standard-rwo → gp3 baseline
# - GCP: fast-rwo → pd-ssd, standard-rwo → pd-balanced

resource "kubernetes_storage_class_v1" "fast_rwo" {
  count = var.enable_storage_class_aliases ? 1 : 0

  metadata {
    name = "fast-rwo"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "k8s-platform/storage-tier" = "high-performance"
    }
  }

  storage_provisioner    = "driver.longhorn.io"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    numberOfReplicas    = var.longhorn_replica_count
    staleReplicaTimeout = "30"
    fsType              = "ext4"
    nodeSelector        = "server-usage:storage"
  }
}

resource "kubernetes_storage_class_v1" "standard_rwo" {
  count = var.enable_storage_class_aliases ? 1 : 0

  metadata {
    name = "standard-rwo"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-bootstrap"
      "k8s-platform/storage-tier" = "standard"
    }
  }

  storage_provisioner    = "csi.hetzner.cloud"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    fsType = "ext4"
  }
}
