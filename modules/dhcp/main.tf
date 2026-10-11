resource "routeros_ip_pool" "agent" {
  name   = "agent_pool"
  ranges = ["10.10.10.11-10.10.10.200"]
}

resource "routeros_ip_pool" "workspace" {
  name   = "workspace_pool"
  ranges = ["10.20.20.10-10.20.20.200"]
}

resource "routeros_ip_pool" "wifi" {
  name   = "wifi_pool"
  ranges = ["10.40.40.10-10.40.40.200"]
}

resource "routeros_ip_dhcp_server" "agent" {
  name         = "agent"
  interface    = "vlan-agent"
  address_pool = routeros_ip_pool.agent.name
  disabled     = false
  depends_on = [
    routeros_ip_pool.agent
  ]
}

resource "routeros_ip_dhcp_server" "workspace" {
  name         = "workspace"
  interface    = "vlan-workspace"
  address_pool = routeros_ip_pool.workspace.name
  disabled     = false
  depends_on = [
    routeros_ip_pool.workspace
  ]
}

resource "routeros_ip_dhcp_server" "wifi" {
  name         = "wifi"
  interface    = "vlan-wifi"
  address_pool = routeros_ip_pool.wifi.name
  disabled     = false
  depends_on = [
    routeros_ip_pool.wifi
  ]
}

resource "routeros_ip_dhcp_server_network" "agent" {
  address    = "10.10.10.0/24"
  gateway    = "10.10.10.1"
  dns_server = ["10.10.10.1"]
}

resource "routeros_ip_dhcp_server_network" "workspace" {
  address    = "10.20.20.0/24"
  gateway    = "10.20.20.1"
  dns_server = ["10.20.20.1"]
}

resource "routeros_ip_dhcp_server_network" "wifi" {
  address    = "10.40.40.0/24"
  gateway    = "10.40.40.1"
  dns_server = ["10.40.40.1"]
}
