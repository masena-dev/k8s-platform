terraform {
  backend "s3" {
    bucket                      = "k8s-starter-state-6426680645"
    key                         = "k8s-platform/clusters/ovh-starter/cluster.tfstate"
    region                      = "gra"
    encrypt                     = true
    endpoints                   = { s3 = "https://s3.gra.io.cloud.ovh.net" }
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    # OVH S3 does not support conditional PUTs required for lock files.
    use_lockfile = false
  }
}
