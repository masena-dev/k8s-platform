# ArgoCD Guide

## Layout

- `argocd/` is the root App-of-Apps chart
- `clusters/<cluster>/values.yaml` holds per-cluster overrides
- AppProjects live in `argocd/templates/projects.yaml`
- Application manifests are split by concern:
  - `projects.yaml`
  - `operators.yaml`
  - `platform.yaml`
  - `data.yaml`
  - `applications.yaml`
  - `bootstrap-secrets.yaml`

## Sync order

ArgoCD sync waves control deployment order. Lower waves deploy first.

| Wave | Applications | Why this wave |
|------|-------------|---------------|
| -6 | prometheus-operator-crds | CRDs must exist before any ServiceMonitor |
| -5 | cert-manager | Webhook + CRDs must be ready before any Certificate request |
| -4 | cert-manager-issuers | ClusterIssuer depends on cert-manager CRDs |
| -3 | external-secrets | ESO operator must be ready before any ExternalSecret |
| -2 | platform-secrets, cnpg-operator, dragonfly-operator | ClusterSecretStore needs ESO; operators need CRDs before instances |
| -1 | bootstrap-secrets, traefik | ExternalSecrets need the store; ingress controller before routes |
| 0 | argocd-ingress, monitoring-middleware, external-dns, kube-prometheus-stack | Core platform services — no ordering dependency between them |
| 1 | loki | Log aggregation — needs Prometheus for ServiceMonitors |
| 2 | alloy | Collector — needs loki-gateway endpoint to exist |
| 3 | (reserved) | Custom applications go here |
| 4 | cnpg-cluster, dragonfly, typesense-cluster, nats | Data layer instances — operators must be at -2 |
| 5 | platform-alerts, demo-app | Last — exercises the full stack |

Verify the live order:

```bash
grep -rn "sync-wave" argocd/templates
```

## Access

Primary URL:

- `https://argocd-<cluster>.<domain>`

If `TF_VAR_onepassword_team_logins_vault_id` is set, Terraform writes an `argocd-<cluster>` browser-login item. See [credential-flow.md](credential-flow.md) for the full item lifecycle.

Break-glass password:

```bash
terraform -chdir=terraform/clusters/$CLUSTER/addons output -raw argocd_admin_password
```

Use username `admin`.

Port-forward fallback:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Private Git repositories

Set `github_token` in the addons stage:

```hcl
argocd_repo_url = "https://github.com/your-org/k8s-platform"
github_token = "ghp_xxxxxxxxxxxx"
```

`github_token` is for ArgoCD Git access only. `ghcr_token` is separate — it is for pulling private images from GHCR. Use a token with read access to the repository ArgoCD should sync.

## Verification

```bash
kubectl get applications -n argocd
kubectl get appprojects -n argocd
kubectl get application -n argocd root -o yaml
```

Verify: `kubectl get applications -n argocd` shows all children `Synced` and `Healthy`; root app tracks the correct repo and branch.

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common ArgoCD sync issues.
