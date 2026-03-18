terraform {
  backend "s3" {
    bucket                      = "k8s-hetzner-state-23654718"
    key                         = "k8s-platform/clusters/hetzner-starter/addons.tfstate"
    region                      = "fsn1"
    endpoints                   = { s3 = "https://fsn1.your-objectstorage.com" }
    use_path_style              = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    # Hetzner Object Storage rejects the backend PutObject variant Terraform uses
    # when backend encryption is enabled.
    encrypt = false
    # Hetzner S3 (Ceph) does not support conditional PUTs required for lock files.
    use_lockfile = false
  }
}
