output "server_ip" {
  description = "Public IP of the dev server"
  value       = hcloud_server.dev.ipv4_address
}
