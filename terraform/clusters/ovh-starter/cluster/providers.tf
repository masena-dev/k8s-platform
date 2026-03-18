terraform {
  required_version = "~> 1.14"
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.9"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "ovh" {
  endpoint           = var.ovh_endpoint
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

provider "openstack" {
  auth_url  = var.openstack_auth_url
  user_name = var.openstack_user_name
  password  = var.openstack_token != "" ? null : var.openstack_password
  token     = var.openstack_token != "" ? var.openstack_token : null
  # OVH projects are identified by UUID; use it as the project/tenant ID.
  tenant_id = var.openstack_tenant_name
  region    = var.region
}
