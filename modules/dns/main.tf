resource "routeros_ip_dns" "dns" {
  allow_remote_requests = true
  servers               = ["1.1.1.1", "8.8.8.8"]
}
