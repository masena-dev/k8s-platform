terraform {
  required_version = "~> 1.14"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

# Read cluster outputs from Stage 1 state.
# terraform init succeeds before the cluster is applied; plan/apply will fail if
# the state file doesn't exist — this is expected: run apply-cluster first.
data "terraform_remote_state" "cluster" {
  backend = "s3"
  config = {
    bucket                      = var.state_bucket
    key                         = "k8s-platform/clusters/hetzner-starter/cluster.tfstate"
    region                      = var.state_region
    endpoints                   = { s3 = var.state_endpoint }
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    # Hetzner S3 (Ceph) requires path-style access and does not support lock files.
    use_path_style = true
    use_lockfile   = false
    encrypt        = false
  }
}

locals {
  kubeconfig      = yamldecode(data.terraform_remote_state.cluster.outputs.kubeconfig)
  current_context = local.kubeconfig["current-context"]
  context         = [for c in local.kubeconfig.contexts : c if c.name == local.current_context][0].context
  cluster         = [for c in local.kubeconfig.clusters : c if c.name == local.context.cluster][0].cluster
  user            = [for u in local.kubeconfig.users : u if u.name == local.context.user][0].user
}

provider "helm" {
  kubernetes = {
    host                   = local.cluster.server
    cluster_ca_certificate = base64decode(local.cluster["certificate-authority-data"])
    client_certificate     = base64decode(local.user["client-certificate-data"])
    client_key             = base64decode(local.user["client-key-data"])
  }
}

provider "kubernetes" {
  host                   = local.cluster.server
  cluster_ca_certificate = base64decode(local.cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.user["client-certificate-data"])
  client_key             = base64decode(local.user["client-key-data"])
}

provider "kubectl" {
  host                   = local.cluster.server
  cluster_ca_certificate = base64decode(local.cluster["certificate-authority-data"])
  client_certificate     = base64decode(local.user["client-certificate-data"])
  client_key             = base64decode(local.user["client-key-data"])
  load_config_file       = false
}

provider "onepassword" {
  # Auth via OP_SERVICE_ACCOUNT_TOKEN env var
}
