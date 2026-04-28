variable "wan_interface" {}

################################
# INPUT
################################

resource "routeros_ip_firewall_filter" "input_established" {
  chain            = "input"
  action           = "accept"
  connection_state = "established,related"
}

resource "routeros_ip_firewall_filter" "input_icmp" {
  chain    = "input"
  action   = "accept"
  protocol = "icmp"
}

resource "routeros_ip_firewall_filter" "input_dns_udp" {
  chain    = "input"
  action   = "accept"
  protocol = "udp"
  dst_port = "53"
}

resource "routeros_ip_firewall_filter" "input_dns_tcp" {
  chain    = "input"
  action   = "accept"
  protocol = "tcp"
  dst_port = "53"
}

resource "routeros_ip_firewall_filter" "drop_wan_input" {
  chain             = "input"
  action            = "drop"
  in_interface_list = "WAN"
}

################################
# FORWARD
################################

resource "routeros_ip_firewall_filter" "fasttrack" {
  chain            = "forward"
  action           = "fasttrack-connection"
  connection_state = "established,related"
}

resource "routeros_ip_firewall_filter" "forward_established" {
  chain            = "forward"
  action           = "accept"
  connection_state = "established,related"
}

resource "routeros_ip_firewall_filter" "drop_invalid" {
  chain            = "forward"
  action           = "drop"
  connection_state = "invalid"
}

resource "routeros_ip_firewall_filter" "lan_to_wan" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = "LAN"
  out_interface_list = "WAN"
}

resource "routeros_ip_firewall_filter" "block_wifi_agent" {
  chain       = "forward"
  action      = "drop"
  src_address = "10.40.40.0/24"
  dst_address = "10.10.10.0/24"
}

resource "routeros_ip_firewall_filter" "block_workspace_server" {
  chain       = "forward"
  action      = "drop"
  src_address = "10.20.20.0/24"
  dst_address = "10.30.30.0/24"
}

################################
# OUTPUT
################################

resource "routeros_ip_firewall_filter" "output_established" {
  chain            = "output"
  action           = "accept"
  connection_state = "established,related"
}

resource "routeros_ip_firewall_filter" "output_dns_udp" {
  chain    = "output"
  action   = "accept"
  protocol = "udp"
  dst_port = "53"
}

resource "routeros_ip_firewall_filter" "output_dns_tcp" {
  chain    = "output"
  action   = "accept"
  protocol = "tcp"
  dst_port = "53"
}

resource "routeros_ip_firewall_filter" "output_allow" {
  chain  = "output"
  action = "accept"
}
