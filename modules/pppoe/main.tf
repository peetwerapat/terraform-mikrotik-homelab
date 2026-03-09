variable "pppoe_user" {}
variable "pppoe_password" {}

resource "routeros_interface_pppoe_client" "pppoe" {
  name      = "pppoe-out1"
  interface = "ether1"

  user     = var.pppoe_user
  password = var.pppoe_password

  max_mtu = 1492
  max_mru = 1492

  add_default_route = true
  use_peer_dns      = false
  disabled          = false
}

output "interface" {
  value = routeros_interface_pppoe_client.pppoe.name
}
