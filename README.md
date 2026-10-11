# Terraform MikroTik Homelab

Infrastructure as Code for a MikroTik RouterOS home network, using the
[terraform-routeros](https://github.com/terraform-routeros/terraform-routeros) provider.

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

| Module     | Description |
|------------|-------------|
| `bridge`   | Bridge with VLAN filtering and ingress-filtered access ports |
| `vlan`     | VLAN interfaces (agent, workspace, server, wifi) |
| `ip`       | IP addresses on VLAN and management interfaces |
| `dhcp`     | DHCP servers and pools (agent, workspace, wifi) |
| `dns`      | DNS resolver forwarding to Pi-hole at `10.10.10.10` |
| `pppoe`    | PPPoE client on ether1 |
| `nat`      | Interface lists (LAN/WAN) and masquerade |
| `firewall` | Input/forward chains with explicit order (`place_before`) and default deny |
| `services` | `/ip service` hardening + `/system identity` |

## DNS through Pi-hole

The Pi-hole host has the static address `10.10.10.10` on VLAN 10. DHCP continues
to advertise each VLAN's MikroTik gateway as its DNS server. RouterOS accepts DNS
requests from LAN clients and forwards them to Pi-hole, so the default-deny
inter-VLAN firewall policy does not need an exception. Pi-hole sees the router's
VLAN 10 address as the DNS client rather than each individual device.

Pi-hole uses `1.1.1.1` and `8.8.8.8` as its upstream DNS servers. Keep Pi-hole as
the router's only upstream to avoid clients bypassing its blocklists. DNS
resolution for the LAN depends on Pi-hole being online; switch the router's
upstream back to a reachable resolver if Pi-hole is unavailable.

The agent DHCP pool starts at `10.10.10.11` so it does not assign the Pi-hole
host's static address.

## Security model

- **Forward chain** is default-deny. Only `LAN → WAN` is accepted; **all inter-VLAN
  traffic is dropped unless an explicit allow is added** before `forward_drop_all`.
- **Input chain** accepts established/related, ICMP, and any traffic from the `LAN`
  interface list. Anything else (including all WAN input) is dropped.
- **Service exposure** is restricted via `/ip service address=` to `mgmt_allowed_ips`.
  `telnet` and `ftp` are disabled.
- **Bridge access ports** (`ether2`–`ether4`) use `frame_types=admit-only-untagged-and-priority-tagged`
  with `ingress_filtering=true` to prevent VLAN hopping.

### Allowing specific inter-VLAN traffic

Add a rule in `modules/firewall/main.tf` above `forward_drop_all`, for example:

```hcl
resource "routeros_ip_firewall_filter" "workspace_to_server_ssh" {
  chain        = "forward"
  action       = "accept"
  src_address  = "10.20.20.0/24"
  dst_address  = "10.30.30.0/24"
  protocol     = "tcp"
  dst_port     = "22"
  place_before = routeros_ip_firewall_filter.forward_drop_all.id
}
```

## Variables

| Variable           | Required | Default                                     | Description |
|--------------------|----------|---------------------------------------------|-------------|
| `router_host`      | yes      | —                                           | RouterOS host URL or IP |
| `router_user`      | yes      | —                                           | RouterOS API user |
| `router_password`  | yes      | —                                           | RouterOS API password (sensitive) |
| `pppoe_user`       | yes      | —                                           | ISP PPPoE username |
| `pppoe_password`   | yes      | —                                           | ISP PPPoE password (sensitive) |
| `system_identity`  | no       | `homelab-router`                            | RouterOS identity |
| `mgmt_allowed_ips` | no       | `["10.40.40.0/24", "192.168.99.0/24"]`      | CIDRs allowed to reach winbox/ssh/api/www |

## Prerequisites

- Terraform >= 1.5
- MikroTik router with RouterOS API enabled
- Your workstation must be on one of the `mgmt_allowed_ips` CIDRs **before** applying
  (the apply restricts service addresses — you can lock yourself out otherwise)

## Run steps (applying to a live router)

> **Read this section before running `apply`.** This config changes firewall behavior
> and management-service exposure on a live router.

1. **Back up the router config first** (RouterOS terminal):

   ```routeros
   /export file=before-terraform-apply
   /system backup save name=before-terraform-apply
   ```

   Download both files via Files → drag to your machine.

2. **Verify your client IP** is inside `mgmt_allowed_ips`. Default covers the
   wifi VLAN (`10.40.40.0/24`) and ether5 mgmt (`192.168.99.0/24`). If you manage
   from somewhere else, update `var.mgmt_allowed_ips` first.

3. **Init & plan**:

   ```bash
   terraform init -upgrade
   terraform plan -var-file=env/home.tfvars -out=plan.tfplan
   ```

   Review the plan. Expect:
   - **~adds**: `input_invalid`, `input_lan`, `input_drop_all`, `forward_drop_all`,
     LAN interface-list members for each VLAN, services module resources.
   - **~changes**: existing firewall rules get `comment` + `place_before` set
     (in-place updates, including a move operation in RouterOS).
   - **~destroys**: `block_wifi_agent`, `block_workspace_server` (subsumed by default deny);
     `input_dns_udp`, `input_dns_tcp`, `drop_wan_input` (subsumed by `input_lan` + `input_drop_all`);
     all `output_*` rules (RouterOS output defaults to accept).

4. **Apply**:

   ```bash
   terraform apply plan.tfplan
   ```

   Brief network blips are possible while firewall rules are reshuffled.

5. **Verify on the router**:

   ```routeros
   /ip firewall filter print
   /ip firewall nat print
   /interface list member print
   /ip service print
   ```

   Confirm the input/forward chain order matches the comments above.

6. **Smoke-test connectivity**:
   - From each VLAN: ping `8.8.8.8` (LAN → WAN should work).
   - From workspace VLAN: ping a host in server VLAN (should **fail** — default deny).
   - winbox/ssh from outside `mgmt_allowed_ips` (should **fail**).

### Rollback

If something is broken and you cannot reach the router:

1. Console in via serial / direct ethernet on ether5 (`192.168.99.0/24`).
2. Restore: `/system backup load name=before-terraform-apply`
3. Investigate, fix, re-plan.

## Future improvements

- **Remote state**: the `terraform.tfstate` is currently local. Consider an S3/MinIO/HTTP
  backend so state isn't lost if the workstation dies.
- **Secret management**: move `env/home.tfvars` secrets into `TF_VAR_*` env vars or a
  secret manager (sops, Vault) and stop committing the file pattern.
- **VLAN refactor**: collapse `modules/vlan`, `modules/ip`, `modules/dhcp` into a single
  `for_each` over a locals map (would need `moved` blocks to migrate state safely).
- **NTP**: add `routeros_system_ntp_client` for time sync.
