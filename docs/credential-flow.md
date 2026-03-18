# Credential Flow

## Bootstrap flow

1. Stage 2 Terraform creates the `onepassword-token` Secret for ESO.
2. ArgoCD installs ESO.
3. ArgoCD installs the `platform-secrets` app, which creates the
   `ClusterSecretStore`.
4. ArgoCD installs `bootstrap-secrets`.
5. ESO reads 1Password items and writes namespace-local Kubernetes Secrets.
6. ArgoCD installs `monitoring-middleware`, which reads
   `monitoring/monitoring-basic-auth`.

When CNPG is enabled, Stage 2 also creates the `database` namespace early so bootstrap secrets exist before the CNPG app syncs.

The kit uses 1Password via ESO's `onepasswordSDK` provider. To use a different backend (AWS Secrets Manager, Vault, Azure Key Vault), update the `ClusterSecretStore` spec in `values/platform-secrets/templates/cluster-secret-store.yaml` and its auth credentials. ExternalSecret manifests reference the store by name and require no changes.

## How secrets reach workloads

Terraform creates Kubernetes Secrets and syncs them to 1Password. ESO keeps Kubernetes Secrets in sync (refresh interval: 5 minutes). Workloads mounting secrets at startup must restart to pick up rotated values.

## Item types

Infrastructure items (for Kubernetes Secret sync via ESO):

- `grafana-<cluster>` when `TF_VAR_onepassword_infra_vault_id` is set
- `loki-s3-<cluster>` when `TF_VAR_onepassword_infra_vault_id` is set and object storage is enabled in Stage 1
- `cloudflare-dns-<cluster>` when `TF_VAR_onepassword_infra_vault_id` is set
- `monitoring-basic-auth-<cluster>` when `TF_VAR_onepassword_infra_vault_id` is set
- `grafana-oidc-<cluster>` when Grafana OAuth is enabled and `TF_VAR_onepassword_infra_vault_id` is set
- `argocd-oidc-<cluster>` when ArgoCD OIDC is enabled and `TF_VAR_onepassword_infra_vault_id` is set
- `database-<cluster>` when the database contract is enabled and `TF_VAR_onepassword_infra_vault_id` is set

Terraform creates `grafana-admin` at bootstrap. `grafana-<cluster>` is the ESO sync item; `grafana-admin-<cluster>` is the browser-login item.

Browser-login items for human access:

- `argocd-<cluster>` when `TF_VAR_onepassword_team_logins_vault_id` is set
- `grafana-admin-<cluster>` when `TF_VAR_onepassword_team_logins_vault_id` is set
- `prometheus-<cluster>` when `TF_VAR_onepassword_team_logins_vault_id` is set
- `alertmanager-<cluster>` when `TF_VAR_onepassword_team_logins_vault_id` is set
- `kubeconfig-oidc-<cluster>` when kubectl OIDC is enabled and a team-logins
  vault is configured

## Managed PostgreSQL credentials

When OVH managed PostgreSQL is enabled (`database_provider = "managed"`, OVH only — not available on Hetzner):

1. Stage 1 provisions the database and exports credentials as Terraform outputs
2. Stage 2 creates `database-credentials` Secret in the `demo` namespace (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DATABASE_URL`) and writes `database-<cluster>` to 1Password
3. If `database.enabled: true` in `clusters/<cluster>/bootstrap-secrets.yaml`, ESO syncs the item back for ongoing refresh

When CNPG is used instead, the same Secret contract is populated from Terraform-generated passwords. The workload interface is identical.

## Required environment

Export the service-account token. `OP_SERVICE_ACCOUNT_TOKEN` is auto-aliased in `.env.shared.example`, so you only set the value once:

```bash
export TF_VAR_onepassword_service_account_token="ops.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# OP_SERVICE_ACCOUNT_TOKEN is set automatically via the alias in .env.shared.example
```

Infrastructure vault — ESO uses the vault **name**, Terraform uses the vault **UUID**:

```bash
export TF_VAR_onepassword_infra_vault="Starter Kit Infra"       # vault name — used by ESO via ClusterSecretStore
export TF_VAR_onepassword_infra_vault_id="<vault-uuid>"          # vault UUID — used by Terraform to write items
```

ESO `ClusterSecretStore` uses the vault **name** (`TF_VAR_onepassword_infra_vault`); Terraform uses the vault **UUID** (`TF_VAR_onepassword_infra_vault_id`). Both must be set.

Optional team browser-login vault:

```bash
export TF_VAR_onepassword_team_logins_vault_id="<vault-uuid>"
```

## Secret consumption

Common Kubernetes Secret bindings:

- external-dns reads `external-dns/cloudflare-api-token`
- Grafana reads `monitoring/grafana-admin`
- Grafana OAuth reads `monitoring/grafana-oauth` (when OAuth is enabled)
- Loki reads `monitoring/loki-storage-credentials`
- Prometheus and Alertmanager ingress read `monitoring/monitoring-basic-auth`
- demo workloads read `demo/database-credentials` (DATABASE_URL, DB_HOST, etc.)
- CNPG uses `database/postgres-app-bootstrap` for its internal superuser
- CNPG backups read `database/cnpg-backup-credentials` for S3 access

## Verification

```bash
kubectl get clustersecretstore
kubectl get externalsecret -A
kubectl get secret -n monitoring grafana-admin
kubectl get secret -n monitoring monitoring-basic-auth
kubectl get secret -n database cnpg-backup-credentials
```

## Common issues

- wrong vault name or vault UUID
- missing `TF_VAR_onepassword_service_account_token` (also sets `OP_SERVICE_ACCOUNT_TOKEN` via alias)
- wrong item title or field name in the referenced 1Password item
- duplicate 1Password items with the same title (e.g. from a partial
  `terraform apply` that created items then failed). ESO returns
  `"more than one item matched the secret reference query"`. Fix by
  deleting duplicates, or pin specific item UUIDs via
  `onepasswordItemUuids` in `argocd/values.yaml`
