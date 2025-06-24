output "reserved_ip" {
  description = "The shared DigitalOcean reserved IP address"
  value       = digitalocean_reserved_ip.shared.ip_address
}

output "reserved_ip_urn" {
  value = digitalocean_reserved_ip.shared.urn
}
