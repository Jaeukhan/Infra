terraform {
  required_providers {
    vsphere = {
      source = "local/hashicorp/vsphere"
      version = "2.7.0"
    }
  }
  required_version = ">= 0.13"
    backend "http" {
  }
}