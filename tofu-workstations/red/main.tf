terraform {
  required_version = ">= 1.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.52.1"
    }
  }
}

provider "openstack" {
  alias     = "red"
  auth_url  = "https://openstack.cyberrange.rit.edu:5000/v3"
  region    = "CyberRange"
  tenant_id = var.red_project_id
}
