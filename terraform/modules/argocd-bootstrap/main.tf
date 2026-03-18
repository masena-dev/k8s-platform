locals {
  argocd_helm_values = {
    configs = {
      params = {
        "server.insecure" = true # Traefik terminates TLS; avoids redirect loop
      }
      cm = var.enable_argocd_oidc ? {
        url = "https://argocd-${var.cluster_name}.${var.domain}"
        "oidc.config" = join("\n", [
          "name: SSO",
          "issuer: ${var.oidc_issuer_url}",
          "clientID: ${var.argocd_oidc_client_id}",
          "clientSecret: $argocd-oidc-secret:clientSecret",
          "requestedScopes:",
          "  - openid",
          "  - email",
          "  - profile",
        ])
      } : {}
      rbac = var.enable_argocd_oidc ? {
        "policy.default" = "role:readonly"
      } : {}
    }
    server = {
      service = {
        type = "ClusterIP"
      }
    }
  }
}

# Install ArgoCD via Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version

  values = [yamlencode(local.argocd_helm_values)]

  # Fresh clusters can serve the API but still time out on OpenAPI schema
  # downloads during Helm hook validation. Skip schema validation here because
  # the chart version is pinned and validated in CI/release checks.
  disable_openapi_validation = true
  wait                       = true
  timeout                    = 600
}

# Read the auto-generated admin password after ArgoCD installs
data "kubernetes_secret_v1" "argocd_initial_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }

  depends_on = [helm_release.argocd]
}

# Destroy order matters for App-of-Apps teardown. Deleting the root Application
# starts ArgoCD's cascading prune, but uninstalling ArgoCD immediately after can
# strand child Applications with resources-finalizer.argocd.argoproj.io. This
# short destroy-time pause gives the controller time to remove child apps before
# Helm uninstalls ArgoCD itself.
resource "time_sleep" "argocd_destroy_grace_period" {
  depends_on = [helm_release.argocd]

  destroy_duration = "180s"
}

# Create the root Application that manages all other apps (App-of-Apps)
resource "kubectl_manifest" "root_application" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root"
      namespace = "argocd"
      # App-of-Apps must use the ArgoCD resources finalizer so deleting the
      # root Application prunes the child Applications/AppProjects before the
      # controller is uninstalled.
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      sources = [
        {
          repoURL        = var.repo_url
          targetRevision = var.target_revision
          path           = "argocd"
          helm = {
            valueFiles = concat(
              ["values.yaml"],
              var.cluster_name != "" ? ["$values/clusters/${var.cluster_name}/values.yaml"] : []
            )
            parameters = [
              {
                name  = "repoURL"
                value = var.repo_url
              },
              {
                name  = "targetRevision"
                value = var.target_revision
              },
              {
                name  = "letsencryptEmail"
                value = var.letsencrypt_email
              },
              {
                name  = "cloudProvider"
                value = var.cloud_provider
              },
              {
                name  = "clusterName"
                value = var.cluster_name
              },
              {
                name  = "onepasswordVaultId"
                value = var.onepassword_vault_id
              },
              {
                name  = "onepasswordItemUuids.grafanaAdmin"
                value = var.onepassword_grafana_item_uuid
              },
              {
                name  = "onepasswordItemUuids.cloudflareApiToken"
                value = var.onepassword_cloudflare_item_uuid
              },
              {
                name  = "onepasswordItemUuids.grafanaOAuth"
                value = var.onepassword_grafana_oauth_item_uuid
              },
              {
                name  = "onepasswordItemUuids.argocdOidc"
                value = var.onepassword_argocd_oidc_item_uuid
              },
              {
                name  = "domain"
                value = var.domain
              },
              {
                name  = "lokiBucketNames.chunks"
                value = var.loki_bucket_chunks
              },
              {
                name  = "lokiBucketNames.ruler"
                value = var.loki_bucket_ruler
              },
              {
                name  = "objectStorage.endpoint"
                value = var.object_storage_endpoint
              },
              {
                name  = "objectStorage.region"
                value = var.object_storage_region
              },
              {
                name  = "cnpgBackupBucketName"
                value = var.cnpg_backup_bucket_name
              },
              {
                name  = "onepasswordItemUuids.monitoringBasicAuth"
                value = var.onepassword_monitoring_auth_item_uuid
              },
              {
                name  = "components.grafanaOAuth"
                value = tostring(var.enable_grafana_oauth)
              },
              {
                name  = "grafanaOAuth.allowedDomains"
                value = var.oidc_allowed_domains
              },
              {
                name  = "grafanaOAuth.authUrl"
                value = var.grafana_oauth_auth_url
              },
              {
                name  = "grafanaOAuth.tokenUrl"
                value = var.grafana_oauth_token_url
              },
              {
                name  = "grafanaOAuth.apiUrl"
                value = var.grafana_oauth_api_url
              },
              {
                name  = "grafanaOAuth.scopes"
                value = var.grafana_oauth_scopes
              },
              {
                name  = "components.cnpg"
                value = tostring(var.cnpg_enabled)
              }
            ]
          }
        },
        {
          repoURL        = var.repo_url
          targetRevision = var.target_revision
          ref            = "values"
        }
      ]
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })

  depends_on = [time_sleep.argocd_destroy_grace_period]
}

# Git repo credentials for ArgoCD (if using private repo)
resource "kubectl_manifest" "repo_secret" {
  count = var.github_token != "" ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "repo-creds"
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/secret-type" = "repository"
      }
    }
    stringData = {
      type     = "git"
      url      = var.repo_url
      password = var.github_token
      username = "git"
    }
  })

  depends_on = [helm_release.argocd]
}
