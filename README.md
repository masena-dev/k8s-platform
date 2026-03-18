# Kubernetes Platform

Terraform + ArgoCD setup for provisioning production Kubernetes across clouds. Same platform stack on any supported cloud — DNS, TLS, secrets, monitoring, and GitOps — via a two-stage Terraform flow.

[![Terraform Plan](https://github.com/masena-dev/k8s-platform/actions/workflows/terraform-plan.yml/badge.svg)](https://github.com/masena-dev/k8s-platform/actions/workflows/terraform-plan.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Supported clouds

| Cloud | What you get | Quickstart |
|-------|-------------|------------|
| **OVH Cloud** | Managed Kubernetes (OVH handles the control plane) | [quickstart-ovh.md](docs/quickstart-ovh.md) |
| **Hetzner Cloud** | Self-managed k3s via [kube-hetzner](https://github.com/mysticaltech/terraform-hcloud-kube-hetzner) | [quickstart-hetzner.md](docs/quickstart-hetzner.md) |
| **GCP GKE** | GKE managed Kubernetes | Coming soon |
| **AWS EKS** | EKS managed Kubernetes | Coming soon |

> **Note**: The Hetzner quickstart defaults to ARM (`cax21`) nodes. Switch to `ccx*` or `cpx*` before applying if your workloads require x86.

## What you get

- **Automated DNS and TLS** — push a service with an Ingress, get a valid HTTPS certificate and DNS record (Traefik + cert-manager + external-dns via Cloudflare).
- **Monitoring and logging** — Grafana, Prometheus, and Loki (with S3 backend), plus pre-configured alerts.
- **Secrets without Vault** — External Secrets Operator (ESO) syncs from 1Password into Kubernetes. Set `TF_VAR_onepassword_team_logins_vault_id` and Terraform will auto-create browser logins for ArgoCD, Grafana, and Prometheus.
- **GitOps** — ArgoCD watches your fork and updates the cluster on push via the app-of-apps pattern.
- **A working demo app** — proves ingress, DNS, and TLS end-to-end.

An optional data layer (CloudNativePG, DragonflyDB, Typesense, NATS) is included but disabled by default. See [customization.md](docs/customization.md).

## Architecture decisions

- **Cloudflare for DNS** — Hardcoded into `external-dns` and `cert-manager` to eliminate manual DNS records. This is a hard dependency.
- **1Password for secrets** — Stage 2 writes bootstrap credentials into 1Password, and ESO reads them back. One store handles human logins and cluster secrets—no Vault cluster required.
- **S3 state backend** — Keeps state cloud-agnostic without provider-specific extras like DynamoDB.
- **ArgoCD over Flux** — Stage 2 installs ArgoCD and creates a single root Application to fan out platform components via sync waves.

## How it works

```
Stage 1 (Terraform)          Stage 2 (Terraform)          Steady state
┌─────────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
│ Cluster             │      │ ArgoCD              │      │ Git push            │
│ Node pools          │ ──▶  │ Secret-zero         │ ──▶  │ ArgoCD syncs        │
│ Object storage      │      │ Bootstrap secrets   │      │ Platform updates    │
│ Network             │      │                     │      │                     │
└─────────────────────┘      └─────────────────────┘      └─────────────────────┘
```

Stage 1 provisions the cloud environment. Stage 2 bootstraps ArgoCD with a service account token ("secret-zero"), which then syncs the remaining platform components from your fork. From there, just push to Git.

## Getting started

Fork this repo — ArgoCD tracks your fork. Then follow your cloud's quickstart:

- **[OVH Cloud quickstart](docs/quickstart-ovh.md)**
- **[Hetzner Cloud quickstart](docs/quickstart-hetzner.md)**

Each guide is self-contained: accounts, credentials, config, deploy.

### Prerequisites

**Accounts:**

- **Cloudflare** — a domain managed in Cloudflare for DNS automation
- **1Password** — a service account with an infrastructure vault
- **S3-compatible bucket** — for Terraform state (each cloud quickstart covers which backend to use)

**Tools:**

```
terraform   ~> 1.14
kubectl
helm
aws CLI     (S3-compatible state backends)
packer      (Hetzner only — MicroOS node images)
hcloud CLI  (Hetzner only)
```

## Repo layout

```
terraform/
  clusters/
    ovh-starter/
      cluster/     # Stage 1: cloud resources + Kubernetes cluster
      addons/      # Stage 2: ArgoCD + secret-zero bootstrap
    hetzner-starter/
      cluster/     # Stage 1: kube-hetzner + object storage
      addons/      # Stage 2: ArgoCD + secret-zero bootstrap
  modules/         # Reusable Terraform modules
  platforms/       # Cloud-specific provider modules

argocd/            # Root App-of-Apps Helm chart
clusters/          # Per-cluster GitOps overlays (values.yaml)
values/            # Helm values per component
demo-app/          # Minimal Go app that verifies the full stack
docs/              # Setup guides, reference, troubleshooting
```

## Documentation

| Topic | Guide |
|-------|-------|
| OVH deployment | [quickstart-ovh.md](docs/quickstart-ovh.md) |
| Hetzner deployment | [quickstart-hetzner.md](docs/quickstart-hetzner.md) |
| CI workflows | [ci.md](docs/ci.md) |
| Environment and variables | [configuration.md](docs/configuration.md) |
| OIDC / SSO | [oidc.md](docs/oidc.md) |
| Monitoring | [monitoring.md](docs/monitoring.md) |
| Secrets and 1Password | [credential-flow.md](docs/credential-flow.md) |
| Enabling/disabling components | [customization.md](docs/customization.md) |
| ArgoCD and private repos | [argocd-guide.md](docs/argocd-guide.md) |
| CNPG backups | [backups.md](docs/backups.md) |
| Private images (GHCR) | [container-registry.md](docs/container-registry.md) |
| Troubleshooting | [troubleshooting.md](docs/troubleshooting.md) |

## CI

Pull requests run `terraform validate` and `helm lint` automatically. The manual dispatch workflow handles `plan` and `apply` for OVH and Hetzner. See [ci.md](docs/ci.md).

## License

MIT. See [LICENSE](LICENSE).
