variable "system_identity" {
  type = string
}

variable "mgmt_allowed_ips" {
  type        = list(string)
  description = "CIDRs allowed to access management services"
}

resource "routeros_system_identity" "this" {
  name = var.system_identity
}

locals {
  default_ports = {
    telnet  = 23
    ftp     = 21
    ssh     = 22
    www     = 80
    www-ssl = 443
    winbox  = 8291
    api     = 8728
    api-ssl = 8729
  }

  disabled_services   = ["telnet", "ftp"]
  restricted_services = ["winbox", "ssh", "api", "api-ssl", "www", "www-ssl"]

  mgmt_address_csv = join(",", var.mgmt_allowed_ips)
}

resource "routeros_ip_service" "disabled" {
  for_each = toset(local.disabled_services)
  numbers  = each.value
  port     = local.default_ports[each.value]
  disabled = true
}

resource "routeros_ip_service" "restricted" {
  for_each = toset(local.restricted_services)
  numbers  = each.value
  port     = local.default_ports[each.value]
  disabled = false
  address  = local.mgmt_address_csv
}
