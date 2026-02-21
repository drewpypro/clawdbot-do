# =============================================================================
# Outputs - Clawdbot DO Deployment
# =============================================================================

output "droplet_id" {
  value       = digitalocean_droplet.clawdbot.id
  description = "Droplet ID"
}

output "public_ip" {
  value       = digitalocean_droplet.clawdbot.ipv4_address
  description = "Public IPv4 address"
}

output "private_ip" {
  value       = digitalocean_droplet.clawdbot.ipv4_address_private
  description = "Private VPC IPv4 address"
}

output "firewall_id" {
  value       = digitalocean_firewall.clawdbot.id
  description = "Cloud firewall ID"
}

