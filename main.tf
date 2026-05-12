module "bridge" {
  source = "./modules/bridge"
}

module "vlan" {
  source = "./modules/vlan"
  bridge = module.bridge.bridge_name
}

module "ip" {
  source     = "./modules/ip"
  depends_on = [module.vlan]
}

module "dhcp" {
  source     = "./modules/dhcp"
  depends_on = [module.ip]
}

module "dns" {
  source = "./modules/dns"
}

module "pppoe" {
  source         = "./modules/pppoe"
  pppoe_user     = var.pppoe_user
  pppoe_password = var.pppoe_password
}

module "nat" {
  source        = "./modules/nat"
  wan_interface = module.pppoe.interface
  depends_on    = [module.vlan]
}

module "firewall" {
  source     = "./modules/firewall"
  depends_on = [module.nat]
}

module "services" {
  source           = "./modules/services"
  system_identity  = var.system_identity
  mgmt_allowed_ips = var.mgmt_allowed_ips
}
