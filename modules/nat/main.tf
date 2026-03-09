variable "wan_interface" {}

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

resource "routeros_ip_firewall_nat" "internet" {
  chain              = "srcnat"
  action             = "masquerade"
  out_interface_list = routeros_interface_list.wan.name
  depends_on = [
    routeros_interface_list_member.pppoe
  ]
}
