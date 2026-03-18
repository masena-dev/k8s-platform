# Platform Modules

Platform modules implement cloud-specific Kubernetes cluster provisioning. They are **child modules** — they do NOT configure providers. Provider configuration belongs in the cluster root that calls the platform.

## Directory Structure

```
terraform/platforms/
├── README.md           # This file
├── ovh/                # OVH Cloud
├── hetzner/            # Hetzner Cloud
└── <provider>/         # Additional platform modules follow the same contract
```

## Usage

Platform modules are called from cluster roots:

```hcl
# terraform/clusters/ovh-starter/cluster/main.tf
module "platform" {
  source = "../../../platforms/ovh"

  project_id   = var.openstack_tenant_name
  cluster_name = var.cluster_name
  region       = var.region
  # ... platform-specific variables
}
```

Provider configuration lives in the cluster root's `providers.tf`.

## Output Contract

Every platform module **must** produce these outputs so the addons stage, bootstrap script, and tooling work regardless of cloud:

### Required Outputs

| Output                   | Type   | Sensitive | Description                    |
| ------------------------ | ------ | --------- | ------------------------------ |
| `kubeconfig`             | string | yes       | Full kubeconfig YAML           |
| `cluster_name`           | string | no        | Cluster identifier             |
| `cluster_host`           | string | yes       | Kubernetes API server URL      |
| `cluster_ca_certificate` | string | yes       | Base64-decoded CA certificate  |

### Optional Outputs

These are cloud-specific and should be `null` if not provisioned:

| Output              | Type   | Sensitive | Description            |
| ------------------- | ------ | --------- | ---------------------- |
| `database_host`     | string | no        | Database server host   |
| `database_port`     | number | no        | Database server port   |
| `database_name`     | string | no        | Database name          |
| `database_username` | string | no        | Database username      |
| `database_password` | string | yes       | Database password      |

### Cloud-Specific Outputs

Individual platforms may export additional outputs (e.g., `network_id`, `cluster_id`) for use in platform-specific workflows.

### Object Storage Outputs (Cluster Root)

These outputs are exported by the **cluster root** (not the platform module) when object storage is provisioned. The addons stage reads them from remote state to configure Loki and sync credentials to 1Password.

| Output                        | Type        | Sensitive | Description                                           |
| ----------------------------- | ----------- | --------- | ----------------------------------------------------- |
| `object_storage_access_key`   | string      | yes       | S3-compatible access key                              |
| `object_storage_secret_key`   | string      | yes       | S3-compatible secret key                              |
| `object_storage_endpoint`     | string      | no        | S3 endpoint URL                                       |
| `object_storage_region`       | string      | no        | S3 region/location for the endpoint (e.g. `fsn1` for Hetzner) |
| `object_storage_bucket_names` | map(string) | no        | Map of logical name to actual bucket name             |

## Adding a New Platform

1. Create a new directory: `terraform/platforms/<provider>/`
2. Implement the required files:
   - `main.tf` — Resource composition (NO provider blocks)
   - `variables.tf` — Platform-specific variables (NO provider credentials)
   - `outputs.tf` — Must implement the output contract above
   - `versions.tf` — `required_providers` with `source` only (no version constraints)
3. Create a cluster root to use it: `terraform/clusters/<name>/cluster/`
4. Verify: create a cluster root and run `terraform init -backend=false && terraform validate`
