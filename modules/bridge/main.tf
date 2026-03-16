resource "routeros_interface_bridge" "lan" {
  name           = "bridge-lan"
  vlan_filtering = true
}

resource "routeros_interface_bridge_port" "ether2" {
  bridge    = routeros_interface_bridge.lan.name
  interface = "ether2"
  pvid      = 10
}

resource "routeros_interface_bridge_port" "ether3" {
  bridge    = routeros_interface_bridge.lan.name
  interface = "ether3"
  pvid      = 20
}

resource "routeros_interface_bridge_port" "ether4" {
  bridge    = routeros_interface_bridge.lan.name
  interface = "ether4"
}

resource "routeros_interface_bridge_vlan" "workspace" {
  bridge   = routeros_interface_bridge.lan.name
  vlan_ids = ["10"]

  tagged   = [routeros_interface_bridge.lan.name]
  untagged = ["ether2"]
}

resource "routeros_interface_bridge_vlan" "gaming" {
  bridge   = routeros_interface_bridge.lan.name
  vlan_ids = ["20"]

  tagged   = [routeros_interface_bridge.lan.name]
  untagged = ["ether3"]
}

resource "routeros_interface_bridge_vlan" "server" {
  bridge   = routeros_interface_bridge.lan.name
  vlan_ids = ["30"]

  tagged = [
    routeros_interface_bridge.lan.name,
    "ether4"
  ]
}

resource "routeros_interface_bridge_vlan" "wifi" {
  bridge   = routeros_interface_bridge.lan.name
  vlan_ids = ["40"]

  tagged = [
    routeros_interface_bridge.lan.name,
    "wifi1",
    "wifi2"
  ]
}

output "bridge_name" {
  value = routeros_interface_bridge.lan.name
}
