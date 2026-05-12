################################
# INPUT chain
# Final order (top to bottom in RouterOS):
#   1. input_established  (accept established/related)
#   2. input_invalid      (drop invalid)
#   3. input_icmp         (accept ICMP)
#   4. input_lan          (accept all from LAN interface list)
#   5. input_drop_all     (default deny — also covers WAN input)
#
# Per-service exposure is restricted in modules/services (/ip service address=...).
################################

resource "routeros_ip_firewall_filter" "input_drop_all" {
  chain   = "input"
  action  = "drop"
  comment = "default deny"
}

resource "routeros_ip_firewall_filter" "input_lan" {
  chain             = "input"
  action            = "accept"
  in_interface_list = "LAN"
  comment           = "accept input from LAN (per-service restriction in /ip service)"
  place_before      = routeros_ip_firewall_filter.input_drop_all.id
}

resource "routeros_ip_firewall_filter" "input_icmp" {
  chain        = "input"
  action       = "accept"
  protocol     = "icmp"
  comment      = "accept ICMP"
  place_before = routeros_ip_firewall_filter.input_lan.id
}

resource "routeros_ip_firewall_filter" "input_invalid" {
  chain            = "input"
  action           = "drop"
  connection_state = "invalid"
  comment          = "drop invalid"
  place_before     = routeros_ip_firewall_filter.input_icmp.id
}

resource "routeros_ip_firewall_filter" "input_established" {
  chain            = "input"
  action           = "accept"
  connection_state = "established,related"
  comment          = "accept established/related"
  place_before     = routeros_ip_firewall_filter.input_invalid.id
}

################################
# FORWARD chain
# Final order:
#   1. fasttrack            (fasttrack established/related)
#   2. forward_established  (accept established/related)
#   3. drop_invalid         (drop invalid)
#   4. lan_to_wan           (accept LAN -> WAN)
#   5. forward_drop_all     (default deny — blocks all inter-VLAN by default)
#
# To allow specific inter-VLAN traffic (e.g., workspace -> server),
# add a rule above with `place_before = routeros_ip_firewall_filter.forward_drop_all.id`.
################################

resource "routeros_ip_firewall_filter" "forward_drop_all" {
  chain   = "forward"
  action  = "drop"
  comment = "default deny inter-VLAN"
}

resource "routeros_ip_firewall_filter" "lan_to_wan" {
  chain              = "forward"
  action             = "accept"
  in_interface_list  = "LAN"
  out_interface_list = "WAN"
  comment            = "allow LAN to WAN"
  place_before       = routeros_ip_firewall_filter.forward_drop_all.id
}

resource "routeros_ip_firewall_filter" "drop_invalid" {
  chain            = "forward"
  action           = "drop"
  connection_state = "invalid"
  comment          = "drop invalid"
  place_before     = routeros_ip_firewall_filter.lan_to_wan.id
}

resource "routeros_ip_firewall_filter" "forward_established" {
  chain            = "forward"
  action           = "accept"
  connection_state = "established,related"
  comment          = "accept established/related"
  place_before     = routeros_ip_firewall_filter.drop_invalid.id
}

resource "routeros_ip_firewall_filter" "fasttrack" {
  chain            = "forward"
  action           = "fasttrack-connection"
  connection_state = "established,related"
  comment          = "fasttrack established/related"
  place_before     = routeros_ip_firewall_filter.forward_established.id
}
