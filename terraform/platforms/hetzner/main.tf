# Longhorn configuration for dedicated storage nodes
# Only applied when enable_storage_nodes = true
locals {
  oidc_args = var.enable_oidc && var.oidc_client_id != "" ? [
    "--kube-apiserver-arg=--oidc-issuer-url=${var.oidc_issuer_url}",
    "--kube-apiserver-arg=--oidc-client-id=${var.oidc_client_id}",
    "--kube-apiserver-arg=--oidc-username-claim=${var.oidc_username_claim}",
    "--kube-apiserver-arg=--oidc-username-prefix=${var.oidc_username_prefix}",
    "--kube-apiserver-arg=--oidc-groups-claim=${var.oidc_groups_claim}",
  ] : []

  k3s_registries = yamlencode({
    # Enable Spegel mirroring for all registries. Some Hetzner IP ranges hit
    # upstream registry blocks or throttling, so node-local mirroring removes
    # that bootstrap-time dependency for core system images.
    mirrors = {
      "*" = {}
    }
  })

  longhorn_configuration = {
    persistence = {
      defaultClass = false # hcloud-volumes stays the sole default; use fast-rwo explicitly for database workloads
    }
    defaultSettings = {
      createDefaultDiskLabeledNodes       = true
      defaultDataPath                     = "/var/lib/longhorn"
      nodeDownPodDeletionPolicy           = "delete-both-statefulset-and-deployment-pod"
      storageOverProvisioningPercentage   = "100"
      storageMinimalAvailablePercentage   = "15"
      disableSchedulingOnCordonedNode     = true
      replicaNodeLevelSoftAntiAffinity    = false
      kubernetesClusterAutoscalerEnabled  = true
      taintToleration                     = "storage=true:NoSchedule"
      systemManagedComponentsNodeSelector = "server-usage:storage"
    }
    longhornManager = {
      nodeSelector = { "server-usage" = "storage" }
      tolerations  = [{ key = "storage", operator = "Equal", value = "true", effect = "NoSchedule" }]
    }
    longhornDriver = {
      nodeSelector = { "server-usage" = "storage" }
      tolerations  = [{ key = "storage", operator = "Equal", value = "true", effect = "NoSchedule" }]
    }
  }

  # Accept either raw SSH key material (preferred for TF_VAR_* env usage) or
  # a filesystem path for local development convenience.
  ssh_public_key_value  = fileexists(pathexpand(var.ssh_public_key)) ? file(pathexpand(var.ssh_public_key)) : var.ssh_public_key
  ssh_private_key_value = fileexists(pathexpand(var.ssh_private_key)) ? file(pathexpand(var.ssh_private_key)) : var.ssh_private_key
}

module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }

  source  = "kube-hetzner/kube-hetzner/hcloud"
  version = "2.19.1"

  hcloud_token      = var.hcloud_token
  ssh_public_key    = local.ssh_public_key_value
  ssh_private_key   = local.ssh_private_key_value
  hcloud_ssh_key_id = var.hcloud_ssh_key_id

  cluster_name        = var.cluster_name
  network_region      = var.network_region
  dns_servers         = var.dns_servers
  initial_k3s_channel = var.k3s_channel

  # --- Control plane ---
  control_plane_nodepools = [
    {
      name        = "cp"
      server_type = var.control_plane_server_type
      location    = var.region
      labels      = []
      taints      = []
      count       = var.control_plane_count
    }
  ]

  # --- Worker + optional storage nodes ---
  agent_nodepools = concat(
    [
      {
        name        = "worker"
        server_type = var.server_type
        location    = var.region
        labels      = []
        taints      = []
        count       = var.desired_nodes
      }
    ],
    var.enable_storage_nodes ? [
      {
        name        = "storage"
        server_type = var.storage_server_type
        location    = var.region
        labels = [
          "server-usage=storage",
          "node.longhorn.io/create-default-disk=true",
          "k8s-platform/storage-node-generation=v1"
        ]
        taints = [
          "storage=true:NoSchedule"
        ]
        count = var.storage_node_count
      }
    ] : []
  )

  # --- Selective built-in management ---
  # ArgoCD manages Traefik (cloud overlays, consistent across clouds)
  ingress_controller = "none"

  # ArgoCD manages cert-manager (consistent across clouds)
  enable_cert_manager = false

  # kube-hetzner manages Longhorn (node-local NVMe storage, Hetzner-specific)
  enable_longhorn        = var.enable_storage_nodes
  longhorn_replica_count = var.storage_node_count
  longhorn_fstype        = "ext4"
  longhorn_values        = var.enable_storage_nodes ? yamlencode(local.longhorn_configuration) : ""

  # --- Networking ---
  # P2P registry mirroring (avoids 403 from k8s.gcr.io on blocked Hetzner IPs)
  k3s_exec_server_args = join(" ", concat(["--embedded-registry"], local.oidc_args))
  k3s_registries       = local.k3s_registries
  # Terraform already exposes kubeconfig as an output, so do not write
  # extra local files into the repo during automated starter-kit runs.
  create_kubeconfig    = false
  create_kustomization = false

  # HA + cost optimization
  use_control_plane_lb              = true
  allow_scheduling_on_control_plane = false # Keep workloads off control plane nodes
  automatically_upgrade_k3s         = false # Manual control via Git
  automatically_upgrade_os          = false

  extra_firewall_rules = var.extra_firewall_rules
}
