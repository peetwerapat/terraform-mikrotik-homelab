variable "router_host" {
  type        = string
  description = "RouterOS host URL or IP (e.g., https://10.40.40.1)"
}

variable "router_user" {
  type        = string
  description = "RouterOS API user"
}

variable "router_password" {
  type        = string
  sensitive   = true
  description = "RouterOS API password"
}

variable "pppoe_user" {
  type        = string
  description = "ISP PPPoE username"
}

variable "pppoe_password" {
  type        = string
  sensitive   = true
  description = "ISP PPPoE password"
}

variable "system_identity" {
  type        = string
  default     = "homelab-router"
  description = "RouterOS /system identity name"
}

variable "mgmt_allowed_ips" {
  type        = list(string)
  description = "CIDRs allowed to reach management services (winbox/ssh/api/www)"
  default = [
    "10.40.40.0/24",  # wifi VLAN (current admin path)
    "192.168.99.0/24" # mgmt on ether5
  ]
}
