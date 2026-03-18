# OIDC RBAC Bindings
#
# Binds OIDC-authenticated users to Kubernetes ClusterRoles.
# Users are identified by "${oidc_username_prefix}${email}" (e.g., "oidc:user@example.com").
#
# Usage:
#   oidc_viewers = ["dev1@example.com", "dev2@example.com"]  -> view (read-only)
#   oidc_admins  = ["ops@example.com"]                       -> cluster-admin

resource "kubectl_manifest" "oidc_viewers" {
  count = length(var.oidc_viewers) > 0 ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "oidc-viewers"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "view"
    }
    subjects = [
      for email in var.oidc_viewers : {
        apiGroup = "rbac.authorization.k8s.io"
        kind     = "User"
        name     = "${var.oidc_username_prefix}${email}"
      }
    ]
  })
}

resource "kubectl_manifest" "oidc_admins" {
  count = length(var.oidc_admins) > 0 ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "oidc-admins"
      labels = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "cluster-admin"
    }
    subjects = [
      for email in var.oidc_admins : {
        apiGroup = "rbac.authorization.k8s.io"
        kind     = "User"
        name     = "${var.oidc_username_prefix}${email}"
      }
    ]
  })
}
