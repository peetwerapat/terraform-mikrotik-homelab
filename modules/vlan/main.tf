variable "bridge" {}

resource "routeros_interface_vlan" "workspace" {
  name      = "vlan-workspace"
  interface = var.bridge
  vlan_id   = 10
}

resource "routeros_interface_vlan" "gaming" {
  name      = "vlan-gaming"
  interface = var.bridge
  vlan_id   = 20
}

resource "routeros_interface_vlan" "server" {
  name      = "vlan-server"
  interface = var.bridge
  vlan_id   = 30
}

resource "routeros_interface_vlan" "wifi" {
  name      = "vlan-wifi"
  interface = var.bridge
  vlan_id   = 40
}
