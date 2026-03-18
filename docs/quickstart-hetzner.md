# Hetzner Cloud Quickstart

Deploy a cluster on Hetzner Cloud using Terraform. MicroOS snapshots must be built locally via Packer before Stage 1. Covers local and GitHub Actions CI.

> If your team uses Google Workspace, Azure AD, or another OAuth provider, configure OIDC before your first cluster apply — Hetzner bakes OIDC flags into k3s at install time and cannot add them later without destroying the cluster. See [oidc.md](oidc.md).

## 1. Prerequisites

Install:

- `terraform` (~> 1.14)
- `kubectl`
- `helm`
- `aws` CLI (for S3-compatible state backend)
- `packer` (for building MicroOS node images -- [install guide](https://developer.hashicorp.com/packer/install))
- `hcloud` (for verifying snapshots and resources)

Verify:

```bash
terraform version
kubectl version --client
helm version
aws --version
packer --version
hcloud version
```

**Required accounts:**

- **Cloudflare** -- a domain managed in Cloudflare for DNS automation. [Create an API token](https://dash.cloudflare.com/profile/api-tokens) using the "Edit zone DNS" template, scoped to your domain's zone.
- **1Password** -- a service account with read/write access to an infrastructure vault. Create one in your 1Password admin console under Developer > Service Accounts. You need the vault **name** (e.g. `Starter Kit Infra`) or the vault **UUID** (visible in the URL at Settings > Vaults) — either one works. Also set up a **team logins vault** (can be the same vault or a separate one shared with your team) — Terraform writes browser-login items here for ArgoCD, Grafana, Prometheus, and Alertmanager so your team can log in via 1Password.
- **Hetzner Cloud** -- a project with API access (credentials covered in step 3).

If you plan to use CI (Option B in step 11), you also need admin access to your GitHub fork to create environments and add secrets.

## 2. Fork and clone

ArgoCD tracks your Git repo during Stage 2, so start from your own fork:

```bash
git clone https://github.com/YOUR-ORG/k8s-platform.git
cd k8s-platform
```

## 3. Hetzner credentials

**API token** -- in the Hetzner Cloud Console, open your project and go to Security > API Tokens. Create a token with Read & Write permissions.

```bash
export TF_VAR_hcloud_token="<hetzner-api-token>"
```

**SSH key pair** -- kube-hetzner needs your SSH key. The variables accept either raw key contents or a file path:

```bash
export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_ed25519.pub)"
export TF_VAR_ssh_private_key="$(cat ~/.ssh/id_ed25519)"
```

Use whichever key pair you prefer. The `.env.hetzner.example` file has the same pattern.

## 4. Build MicroOS snapshots

kube-hetzner provisions nodes using openSUSE MicroOS snapshots. This step **must** run before Stage 1.

```bash
curl -sLO https://raw.githubusercontent.com/mysticaltech/terraform-hcloud-kube-hetzner/master/packer-template/hcloud-microos-snapshots.pkr.hcl
export HCLOUD_TOKEN="$TF_VAR_hcloud_token"
packer init hcloud-microos-snapshots.pkr.hcl
packer build hcloud-microos-snapshots.pkr.hcl
```

Verify the snapshots exist:

```bash
hcloud image list --type snapshot --selector microos-snapshot=yes
```

Snapshots are reusable across clusters in the same Hetzner project.

> Packer snapshots must be built locally. The CI workflow assumes snapshots already exist in your Hetzner project.

## 5. Configure environment

Build your `.env` from the split example files:

```bash
cp .env.shared.example .env
cat .env.hetzner.example >> .env
```

Optionally append OIDC and extras:

```bash
cat .env.oidc.example >> .env      # SSO for kubectl, Grafana, ArgoCD
cat .env.extras.example >> .env    # GHCR, GitHub token for private repos
```

Fill in the values using the credentials from step 3, then export:

```bash
source .env
```

Never commit `.env` to git. Run the `cp`/`cat` steps once. Delete `.env` before re-running.

### Config surface

Three files control the deployment:

- **`.env`** -- secrets and values shared across stages. Exported as `TF_VAR_*` environment variables. Never committed.
- **`terraform.tfvars`** -- per-stage choices (cluster size, features, domain). One file per stage directory.
- **`backend.tf`** -- S3 state backend config per stage. Committed to the repo (contains no secrets).

## 6. Create a Terraform state bucket

1. Go to **Hetzner Cloud Console > Object Storage > Create Bucket**
2. Pick a region and name the bucket (e.g., `k8s-state-{random}`). **If you plan to use CI, pick `fsn1`** — the workflow hardcodes this region for the state backend. See [ci.md](ci.md#backend-config) to change it.
3. Create access credentials: **Object Storage > Manage credentials**
4. Add the access key and secret key to `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in your `.env`
5. Set `TF_VAR_state_bucket`, `TF_VAR_state_region`, and `TF_VAR_state_endpoint` in `.env`

`TF_VAR_state_region` is the **bucket** location code (e.g. `fsn1`), not a cluster config value.

These credentials can be reused for `TF_VAR_object_storage_access_key`/`secret_key` when object storage is enabled.

Re-source after adding the new values:

```bash
source .env
```

## 7. Backend config

Update the `backend "s3"` block in both
`terraform/clusters/hetzner-starter/cluster/backend.tf` and
`terraform/clusters/hetzner-starter/addons/backend.tf` with your own bucket name
and endpoint.

If you rename the cluster directory or change `cluster_name`, also update the `key` field in both `backend.tf` files and the remote state `key` in `addons/providers.tf` — these are hardcoded to `hetzner-starter`.

Keep the backend location code and endpoint host aligned:

| Region | Endpoint |
|--------|----------|
| `fsn1` | `https://fsn1.your-objectstorage.com` |
| `nbg1` | `https://nbg1.your-objectstorage.com` |
| `hel1` | `https://hel1.your-objectstorage.com` |

## 8. Stage 1 config -- cluster

Create the cluster tfvars:

```bash
cp terraform/clusters/hetzner-starter/cluster/terraform.tfvars.example \
  terraform/clusters/hetzner-starter/cluster/terraform.tfvars
```

Minimum starting point:

```hcl
cluster_name = "hetzner-starter"
domain       = "example.com"
region       = "nbg1"

control_plane_server_type = "cax21"
control_plane_count       = 1

server_type   = "cax21"
desired_nodes = 2

enable_object_storage = true
```

`control_plane_count = 1` is the minimal starting point; the code default is `3` for HA. Always set `control_plane_server_type` explicitly — the default (`cpx22`, shared x86) differs from the `cax21` (ARM) shown above.

If you plan to use OIDC, also add:

```hcl
enable_oidc    = true
oidc_client_id = "your-kubectl-client-id"
```

### Choosing server types

Pick the right instance family for your workload:

| Family | CPU | Best for | Notes |
| --- | --- | --- | --- |
| `cax*` | ARM (Ampere) | General workloads | Lowest cost per vCPU, default |
| `ccx*` | Dedicated x86 | x86-only images, production | Reliable CSI volume hotplug |
| `cpx*` | Shared x86 | Dev/test budgets | May have CSI volume hotplug issues |
| `cx*` | Shared x86 (new gen) | General purpose | Starts at `cx23` |

The `cax21` (4 ARM vCPU, 8 GB) runs the full platform stack including monitoring and CNPG.

### Multiple node pools

The kit supports dedicated storage nodes for Longhorn. Enable them in
`terraform.tfvars`:

```hcl
enable_storage_nodes = true
storage_server_type  = "cax41"
storage_node_count   = 2
```

Storage nodes are labeled `server-usage=storage` and tainted
`storage=true:NoSchedule`. Longhorn is automatically enabled when storage nodes
are present.

For advanced Longhorn tuning (replica count, encryption, backup targets), see the [kube-hetzner storage documentation](https://github.com/mysticaltech/terraform-hcloud-kube-hetzner#storage).

If you keep `enable_object_storage = true`, also add these to your `.env`:

```bash
export TF_VAR_object_storage_access_key="<hetzner-object-storage-access-key>"
export TF_VAR_object_storage_secret_key="<hetzner-object-storage-secret-key>"
```

## 9. Push to fork

Push config changes before Stage 2 — ArgoCD clones your fork and deploys demo defaults if changes aren't committed.

```bash
git add terraform/clusters/hetzner-starter/cluster/backend.tf \
       terraform/clusters/hetzner-starter/addons/backend.tf \
       clusters/hetzner-starter/values.yaml
git commit -m "Configure cluster for my environment"
git push origin main
```

## 10. Stage 2 config -- addons

Create the addons tfvars:

```bash
cp terraform/clusters/hetzner-starter/addons/terraform.tfvars.example \
  terraform/clusters/hetzner-starter/addons/terraform.tfvars
```

Minimum starting point:

```hcl
argocd_repo_url        = "https://github.com/YOUR-ORG/k8s-platform.git"
argocd_target_revision = "main"

cloud_provider = "hetzner"
cluster_name   = "hetzner-starter"
domain         = "example.com"

letsencrypt_email = "ops@your-company.com"
# cnpg_enabled    = true   # Optional — see customization.md to enable the data layer
# github_token     = ""   # Only if argocd_repo_url points at a private repo
```

For private repo access, set `github_token`. See [argocd-guide.md](argocd-guide.md#private-git-repositories).

Required environment variables (from [configuration.md](configuration.md)):
`TF_VAR_state_bucket`, `TF_VAR_state_region`, `TF_VAR_state_endpoint`,
`TF_VAR_onepassword_service_account_token`,
`TF_VAR_onepassword_infra_vault_id` (or `TF_VAR_onepassword_infra_vault` — only one is needed),
`TF_VAR_cloudflare_api_token`, `TF_VAR_domain`, `TF_VAR_letsencrypt_email`.

(`OP_SERVICE_ACCOUNT_TOKEN` is auto-aliased from `TF_VAR_onepassword_service_account_token` in `.env.shared.example`.)

## 11. Deploy

### Option A: Deploy locally

Source your environment and apply both stages in order.

**Stage 1 -- cluster:**

```bash
source .env
terraform -chdir=terraform/clusters/hetzner-starter/cluster init
terraform -chdir=terraform/clusters/hetzner-starter/cluster apply
```

Export kubeconfig:

```bash
terraform -chdir=terraform/clusters/hetzner-starter/cluster output -raw kubeconfig > kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

**Stage 2 -- addons:**

```bash
terraform -chdir=terraform/clusters/hetzner-starter/addons init
terraform -chdir=terraform/clusters/hetzner-starter/addons apply
```

### Option B: Deploy via CI (GitHub Actions)

The included workflow handles both stages sequentially. You need admin access to your GitHub fork to create environments and add secrets.

> MicroOS snapshots (step 4) must exist in your Hetzner project before CI runs.
>
> The CI workflow does not set `TF_VAR_object_storage_access_key` or `TF_VAR_object_storage_secret_key`. If object storage is enabled, add these as GitHub secrets and update the workflow, or set `enable_object_storage = false`.

**1. Create a `production` environment** in Settings > Environments. Add required reviewers to gate applies.

**2. Add secrets** in Settings > Secrets and variables > Actions > Secrets:

| `.env` variable | GitHub Secret |
|---|---|
| `AWS_ACCESS_KEY_ID` (S3 state) | `HETZNER_S3_ACCESS_KEY` |
| `AWS_SECRET_ACCESS_KEY` (S3 state) | `HETZNER_S3_SECRET_KEY` |
| `TF_VAR_hcloud_token` | `HCLOUD_TOKEN` |
| `TF_VAR_ssh_public_key` | `HETZNER_SSH_PUBLIC_KEY` |
| `TF_VAR_ssh_private_key` | `HETZNER_SSH_PRIVATE_KEY` |
| `TF_VAR_hcloud_ssh_key_id` | `HETZNER_SSH_KEY_ID` |
| `TF_VAR_state_bucket` | `HETZNER_STATE_BUCKET` |
| `TF_VAR_state_endpoint` | `HETZNER_STATE_ENDPOINT` |
| `TF_VAR_cloudflare_api_token` | `CLOUDFLARE_API_TOKEN` |
| `TF_VAR_onepassword_service_account_token` | `ONEPASSWORD_SERVICE_ACCOUNT_TOKEN` |
| `TF_VAR_onepassword_infra_vault_id` | `ONEPASSWORD_INFRA_VAULT_ID` |

**3. Add variables** in Settings > Secrets and variables > Actions > Variables:

| `.env` variable | GitHub Variable |
|---|---|
| `TF_VAR_cluster_name` | `HETZNER_CLUSTER_NAME` |
| `TF_VAR_domain` | `HETZNER_STARTER_DOMAIN` |
| `TF_VAR_argocd_repo_url` | `ARGOCD_REPO_URL` |
| `TF_VAR_argocd_target_revision` | `ARGOCD_TARGET_REVISION` |
| `TF_VAR_letsencrypt_email` | `LETSENCRYPT_EMAIL` |

Optional: `ARGOCD_GITHUB_TOKEN` (secret, for private repos), `ONEPASSWORD_TEAM_LOGINS_VAULT_ID` (secret), OIDC secrets -- see [ci.md](ci.md) for the full list.

**4. Trigger:** Go to **Actions > Terraform Apply > Run workflow**. Select `hetzner-starter` and `plan` for a dry run, then re-run with `apply` to deploy.

## 12. Verify and access

```bash
kubectl get applications -n argocd
kubectl get ingress -A
kubectl get pods -A
```

Primary URLs:

- `https://argocd-hetzner-starter.<domain>`
- `https://grafana-hetzner-starter.<domain>`
- `https://demo-hetzner-starter.<domain>` (when `demoApp` is enabled)

Use 1Password browser-login items for current credentials. Terraform outputs show bootstrap values only and do not reflect in-UI changes. See [credential-flow.md](credential-flow.md) for the full item lifecycle.

Break-glass passwords (local deploy only — CI deploys don't expose Terraform outputs, use the 1Password items instead):

```bash
terraform -chdir=terraform/clusters/hetzner-starter/addons output -raw argocd_admin_password
terraform -chdir=terraform/clusters/hetzner-starter/addons output -raw grafana_admin_password
```

To enable CNPG, set `cnpg: true` under `components:` in `clusters/hetzner-starter/values.yaml` and `cnpg_enabled = true` in addons `terraform.tfvars`. CNPG backups require object storage (set in Stage 1).

For a private demo app image, create an `imagePullSecret` in the `demo` namespace before enabling `demoApp`.

### Networking

kube-hetzner provisions a Hetzner Cloud private network and attaches all nodes to it — node-to-node traffic stays off the public internet. The Traefik load balancer and the Kubernetes API load balancer are the two public entry points. Outbound traffic is restricted by default to DNS (53), HTTP/HTTPS (80/443), NTP (123), and ICMP — see [customization.md](customization.md#hetzner-firewall-rules) to add extra rules.

Spegel (P2P registry mirroring) is enabled by default — nodes share container images locally to avoid upstream registry throttling on some Hetzner IP ranges. This is transparent but may affect debugging if you see images served from peers instead of upstream registries.

No Kubernetes NetworkPolicies are installed. Pod-to-pod traffic is unrestricted within the cluster. Add NetworkPolicies if you need namespace-level isolation.

## Next steps

- [Customization](customization.md) -- enable/disable components, add your apps
- [Monitoring](monitoring.md) -- access Grafana and Prometheus, route alerts
- [Credential flow](credential-flow.md) -- understand how secrets work
- [OIDC](oidc.md) -- add SSO for your team

## Teardown

Destroy in reverse order -- addons first, then cluster:

```bash
# 1. Destroy addons (ArgoCD, platform components)
terraform -chdir=terraform/clusters/hetzner-starter/addons destroy -auto-approve

# 2. Destroy cluster infrastructure
terraform -chdir=terraform/clusters/hetzner-starter/cluster destroy -auto-approve
```

Destroy includes intentional pauses (60s for external-secrets cleanup, 180s for ArgoCD) — expect it to take several minutes. If destroy fails with a timeout after the pauses, re-run the same command -- transient API errors are common.

Delete stale `heritage=external-dns` TXT records in your Cloudflare dashboard before redeploying to the same domain.

The CI workflow does not include a destroy action. Run teardown locally.
