module "bridge" {
  source = "./modules/bridge"
}

module "vlan" {
  source = "./modules/vlan"
  bridge = module.bridge.bridge_name

  depends_on = [
    module.bridge
  ]
}

module "ip" {
  source = "./modules/ip"

  depends_on = [
    module.vlan
  ]
}

module "dhcp" {
  source = "./modules/dhcp"

  depends_on = [
    module.ip
  ]
}

module "dns" {
  source = "./modules/dns"

  depends_on = [
    module.ip
  ]
}

module "pppoe" {
  source         = "./modules/pppoe"
  pppoe_user     = var.pppoe_user
  pppoe_password = var.pppoe_password
}

module "nat" {
  source        = "./modules/nat"
  wan_interface = module.pppoe.interface

  depends_on = [
    module.pppoe
  ]
}

module "firewall" {
  source        = "./modules/firewall"
  wan_interface = module.pppoe.interface

  depends_on = [
    module.nat
  ]
}
