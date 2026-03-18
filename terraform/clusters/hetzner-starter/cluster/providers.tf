terraform {
  required_version = "~> 1.14"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "aws" {
  alias      = "hetzner_s3"
  region     = var.region
  access_key = var.object_storage_access_key
  secret_key = var.object_storage_secret_key

  s3_use_path_style      = true
  skip_region_validation = true

  endpoints {
    s3 = "https://${var.region}.your-objectstorage.com"
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
