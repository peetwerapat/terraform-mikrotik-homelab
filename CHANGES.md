# Hardening Changes — Summary

สรุปการแก้ไข Terraform MikroTik Homelab รอบนี้ — เปลี่ยนจาก config ที่ใช้งานได้ แต่มีช่องโหว่
ไปเป็น config ที่ default-deny และ management แบบ restricted

## ปัญหาที่พบในของเดิม

| # | ปัญหา | ผลกระทบ |
|---|------|---------|
| 1 | `LAN` interface list ไม่มี member เลย | Firewall rule `lan_to_wan` ไม่ match อะไร — traffic ไหลออกได้เพราะ default accept เท่านั้น |
| 2 | ไม่มี default-deny บน forward chain | Inter-VLAN ติดต่อกันได้หมด ยกเว้น 2 flow ที่ block ไว้ |
| 3 | Input chain ไม่มี source filter บน DNS | Router เป็น open DNS resolver สำหรับ internet (DNS amplification risk) |
| 4 | `place_before` ไม่ถูกใช้ → rule order ไม่ deterministic | Firewall อาจเรียงผิด หลัง apply ครั้งถัดไป |
| 5 | ether2/ether3 ไม่มี `ingress_filtering` | เสี่ยง VLAN hopping |
| 6 | `/ip service` ไม่ harden | telnet/ftp/winbox/ssh/api เปิดให้ทุก IP เข้าได้ |
| 7 | `env/home.tfvars` มี `wg_private_key` ที่ไม่ได้ใช้ | เก็บ secret ทิ้งไว้เปล่าๆ |
| 8 | Variable ไม่มี type / sensitive flag | Password อาจหลุดใน log |
| 9 | Output chain rules ซ้ำซ้อน (default คือ accept อยู่แล้ว) | ไม่มีผล แต่ทำให้อ่าน config ยาก |
| 10 | `depends_on` หลายจุดซ้ำกับ implicit dependency | ไม่มีผล แต่ noise |

## ไฟล์ที่แก้

### `variable.tf` — เพิ่ม type / sensitive / ตัวแปรใหม่
- ทุก variable มี `type` และ `description`
- `router_password`, `pppoe_password` มี `sensitive = true`
- เพิ่ม `system_identity` (default `homelab-router`)
- เพิ่ม `mgmt_allowed_ips` (default `["10.40.40.0/24", "192.168.99.0/24"]`)

### `env/home.tfvars` — ลบของไม่ใช้
- ลบ `client_public_key` และ `wg_private_key`

### `main.tf` — wire module ใหม่ + cleanup
- เพิ่ม `module "services"`
- ลบ `depends_on` ที่ implicit อยู่แล้ว (เช่น vlan ที่ depend on bridge ผ่าน `var.bridge`)

### `modules/bridge/main.tf` — ingress filtering ทุก access port
- เพิ่ม `frame_types = "admit-only-untagged-and-priority-tagged"` กับ `ingress_filtering = true`
  ที่ ether2 และ ether3 (ของ ether4 มีอยู่แล้ว)

### `modules/nat/main.tf` — ใส่ LAN members ที่หายไป
- เพิ่ม `routeros_interface_list_member.lan` แบบ `for_each` ของ
  `vlan-agent`, `vlan-workspace`, `vlan-server`, `vlan-wifi`
- เพิ่ม `comment` บน masquerade rule

### `modules/firewall/main.tf` — เขียนใหม่ทั้งหมด

**Input chain** (top → bottom):
1. `input_established` — accept established/related
2. `input_invalid` *(ใหม่)* — drop invalid
3. `input_icmp` — accept ICMP
4. `input_lan` *(ใหม่)* — accept all from LAN interface list
5. `input_drop_all` *(ใหม่)* — default deny (รวมถึง WAN input)

**Forward chain** (top → bottom):
1. `fasttrack` — fasttrack established/related
2. `forward_established` — accept established/related
3. `drop_invalid` — drop invalid
4. `lan_to_wan` — accept LAN → WAN
5. `forward_drop_all` *(ใหม่)* — default deny inter-VLAN

**ลบออก:**
- `input_dns_udp`, `input_dns_tcp`, `drop_wan_input` (ถูก subsume โดย `input_lan` + `input_drop_all`)
- `block_wifi_agent`, `block_workspace_server` (ถูก subsume โดย `forward_drop_all`)
- `output_established`, `output_dns_udp`, `output_dns_tcp`, `output_allow` (output chain default accept อยู่แล้ว)

**ทุก rule ใช้ `place_before` เพื่อ enforce order** — ไม่ขึ้นกับ Terraform graph order

### `modules/services/main.tf` *(ใหม่)*
- `/system identity` ตั้งชื่อ router
- `routeros_ip_service`:
  - **Disabled**: `telnet`, `ftp`
  - **Restricted by address**: `winbox`, `ssh`, `api`, `api-ssl`, `www`, `www-ssl`
    (จำกัดเฉพาะ `mgmt_allowed_ips`)

### `README.md` — เขียนใหม่
- Security model
- ตัวอย่างการเพิ่ม inter-VLAN allow rule
- Run steps + rollback
- Future improvements (remote state, secret management, for_each refactor, NTP)

## Plan diff (ทีปรับ live router)

```
Plan: 23 to add, 3 to change, 15 to destroy
(+ ~6 firewall rule replaces จาก place_before forces replacement)
```

| Action | Resources |
|--------|-----------|
| Add | LAN list members ×4, firewall rules ใหม่ ×3 (input_invalid/input_lan/input_drop_all/forward_drop_all), services ×9 |
| Change in-place | bridge port ether2/ether3 (ingress filter), nat masquerade (comment) |
| Destroy | output chain rules ×4, block rules ×2, dns input rules ×2, drop_wan_input, replaces ของ rule เก่าจาก place_before |

## Run steps

```bash
# 1. Backup router ใน RouterOS terminal:
#    /export file=before-terraform-apply
#    /system backup save name=before-terraform-apply

# 2. ตรวจว่า client IP อยู่ใน mgmt_allowed_ips (default ครอบ wifi VLAN + ether5)

# 3. Init & plan
terraform init -upgrade
terraform plan -var-file=env/home.tfvars -out=plan.tfplan

# 4. Apply
terraform apply plan.tfplan

# 5. Verify บน router
#    /ip firewall filter print
#    /interface list member print
#    /ip service print

# 6. Smoke test:
#    - ping 8.8.8.8 จากแต่ละ VLAN (ต้องได้)
#    - ping ข้าม VLAN (ต้องไม่ได้ — default deny)
#    - winbox จาก IP นอก mgmt range (ต้องเข้าไม่ได้)
```

**Rollback**: ถ้า reach router ไม่ได้ → เสียบ ether5 ตรง (`192.168.99.0/24`) หรือ serial console
แล้ว `/system backup load name=before-terraform-apply`

## ⚠️ พฤติกรรมเปลี่ยนสำคัญ

**Inter-VLAN เดิม "allow all ยกเว้น 2 flow" → ใหม่ "deny all ยกเว้น LAN→WAN"**

ถ้าเคยมี flow ข้าม VLAN ที่ใช้งานจริง (เช่น workstation SSH ไปยัง server) ต้องเพิ่ม allow rule
เอง วาง **เหนือ** `forward_drop_all` ตัวอย่างใน `README.md` ส่วน "Allowing specific inter-VLAN traffic"

## ยังไม่ได้ทำ (future work)

- **Remote state**: state ยัง local อยู่ ควรย้ายไป S3/MinIO/HTTP backend
- **Secret management**: `env/home.tfvars` ยังมี password ตรงๆ ควรย้ายไป `TF_VAR_*` env หรือ sops/Vault
- **VLAN/IP/DHCP for_each refactor**: ตอนนี้ resource ซ้ำกัน 3-4 ก้อน รวมเป็น map เดียวได้
  แต่ต้องใช้ `moved` block เพื่อ migrate state แบบไม่ destroy ของจริง
- **NTP**: เพิ่ม `routeros_system_ntp_client` สำหรับ time sync
