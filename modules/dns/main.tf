resource "routeros_ip_dns" "dns" {
  allow_remote_requests = true
  servers               = ["10.10.10.10"]
}
