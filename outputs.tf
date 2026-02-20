###############################################################################
# Outputs
###############################################################################
output "droplet_ids" {
  description = "IDs of created droplets"
  value       = digitalocean_droplet.main[*].id
}

output "droplet_names" {
  description = "Names of created droplets"
  value       = digitalocean_droplet.main[*].name
}

output "droplet_public_ips" {
  description = "Public IPv4 addresses of droplets"
  value       = digitalocean_droplet.main[*].ipv4_address
}

output "droplet_private_ips" {
  description = "Private IPv4 addresses of droplets (VPC)"
  value       = digitalocean_droplet.main[*].ipv4_address_private
}

output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.main.id
}

output "vpc_urn" {
  description = "VPC URN"
  value       = digitalocean_vpc.main.urn
}

output "firewall_id" {
  description = "Firewall ID"
  value       = digitalocean_firewall.droplet_fw.id
}

output "ssh_key_fingerprint" {
  description = "SSH key fingerprint"
  value       = digitalocean_ssh_key.main.fingerprint
}

output "ssh_connection" {
  description = "SSH connection command for first droplet"
  value       = length(digitalocean_droplet.main) > 0 ? "ssh root@${digitalocean_droplet.main[0].ipv4_address}" : "no droplets"
}
