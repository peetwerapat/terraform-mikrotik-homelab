resource "routeros_ip_address" "agent" {
  address   = "10.10.10.1/24"
  interface = "vlan-agent"
}

resource "routeros_ip_address" "workspace" {
  address   = "10.20.20.1/24"
  interface = "vlan-workspace"
}

resource "routeros_ip_address" "server" {
  address   = "10.30.30.1/24"
  interface = "vlan-server"
}

resource "routeros_ip_address" "wifi" {
  address   = "10.40.40.1/24"
  interface = "vlan-wifi"
}

resource "routeros_ip_address" "mgmt" {
  address   = "192.168.99.1/24"
  interface = "ether5"
}
