terraform {
  required_version = ">= 1.5"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "~> 1.99"
    }
  }
}

provider "routeros" {
  hosturl  = var.router_host
  username = var.router_user
  password = var.router_password
  insecure = true
}
