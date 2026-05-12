variable "wan_interface" {}

variable "lan_interfaces" {
  type    = list(string)
  default = ["vlan-agent", "vlan-workspace", "vlan-server", "vlan-wifi"]
}

resource "routeros_interface_list" "lan" {
  name = "LAN"
}

resource "routeros_interface_list" "wan" {
  name = "WAN"
}

resource "routeros_interface_list_member" "pppoe" {
  list      = routeros_interface_list.wan.name
  interface = var.wan_interface
}

resource "routeros_interface_list_member" "lan" {
  for_each  = toset(var.lan_interfaces)
  list      = routeros_interface_list.lan.name
  interface = each.value
}

resource "routeros_ip_firewall_nat" "internet" {
  chain              = "srcnat"
  action             = "masquerade"
  out_interface_list = routeros_interface_list.wan.name
  comment            = "masquerade out WAN"

  depends_on = [
    routeros_interface_list_member.pppoe
  ]
}
