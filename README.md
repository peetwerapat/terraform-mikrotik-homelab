# Terraform MikroTik Homelab

Infrastructure as Code for managing a MikroTik RouterOS-based home network using Terraform.

## Overview

This project uses the [terraform-routeros](https://github.com/terraform-routeros/terraform-routeros) provider to declaratively configure a MikroTik router with VLANs, DHCP, DNS, PPPoE, NAT, and firewall rules.

## Network Architecture

```
Internet
   │
   │ PPPoE (ether1)
   │
┌──┴──────────────────────────────┐
│         MikroTik Router         │
│                                 │
│  bridge-lan (VLAN filtering)    │
│  ├── VLAN 10 - Agent            │  10.10.10.0/24
│  ├── VLAN 20 - Workspace        │  10.20.20.0/24
│  ├── VLAN 30 - Server           │  10.30.30.0/24
│  └── VLAN 40 - WiFi             │  10.40.40.0/24
│                                 │
│  Management (ether5)            │  192.168.99.0/24
└─────────────────────────────────┘
   │         │         │
 ether2    ether3    ether4
(PVID 10) (PVID 20) (PVID 30)
```

## Modules

| Module | Description |
|--------|-------------|
| `bridge` | Creates bridge interface with VLAN filtering and port assignments |
| `vlan` | Defines VLAN interfaces (agent, workspace, server, wifi) |
| `ip` | Assigns IP addresses to VLAN and management interfaces |
| `dhcp` | Configures DHCP servers and pools for agent, workspace, and wifi networks |
| `dns` | Sets up DNS resolver with Cloudflare (1.1.1.1) and Google (8.8.8.8) upstreams |
| `pppoe` | Configures PPPoE client on ether1 for WAN connectivity |
| `nat` | Configures source NAT (masquerade) for internet access |
| `firewall` | Implements input, forward, and output firewall rules |

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- A MikroTik router running RouterOS
- API access enabled on the router

## Usage

1. Clone the repository:

   ```bash
   git clone https://github.com/<your-username>/terraform-mikrotik-homelab.git
   cd terraform-mikrotik-homelab
   ```

2. Create a `terraform.tfvars` file with your configuration:

   ```hcl
   router_host     = "YOUR_ROUTER_HOST"
   router_user     = "YOUR_ROUTER_USER"
   router_password = "YOUR_ROUTER_PASSWORD"

   pppoe_user     = "YOUR_PPPOE_USER"
   pppoe_password = "YOUR_PPPOE_PASSWORD"
   ```

3. Initialize and apply:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Variables

| Variable | Description |
|----------|-------------|
| `router_host` | RouterOS API URL |
| `router_user` | RouterOS username |
| `router_password` | RouterOS password |
| `pppoe_user` | ISP PPPoE username |
| `pppoe_password` | ISP PPPoE password |

## Firewall Rules Summary

**Input chain:** Accepts established/related connections and ICMP, allows DNS, drops all WAN input.

**Forward chain:** Fast-tracks established connections, allows LAN-to-WAN, blocks WiFi-to-agent and workspace-to-server cross-VLAN traffic.

**Output chain:** Accepts established connections and DNS traffic.

## License

This project is provided as-is for personal use.
