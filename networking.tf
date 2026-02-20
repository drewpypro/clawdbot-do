###############################################################################
# VPC
###############################################################################
resource "digitalocean_vpc" "main" {
  name     = "${var.project_name}-${var.environment}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
}

###############################################################################
# Firewall
###############################################################################
resource "digitalocean_firewall" "droplet_fw" {
  name = "${var.project_name}-${var.environment}-fw"

  droplet_ids = digitalocean_droplet.main[*].id

  # SSH — restricted to allowed CIDRs
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_cidrs
  }

  # ICMP (ping) — restricted to allowed CIDRs
  inbound_rule {
    protocol         = "icmp"
    source_addresses = var.allowed_ssh_cidrs
  }

  # Outbound — HTTPS only (API calls, package updates, Discord WebSocket)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound — HTTP (package repos that use HTTP)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound — DNS
  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound — NTP
  outbound_rule {
    protocol              = "udp"
    port_range            = "123"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound — ICMP
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  depends_on = [digitalocean_droplet.main]
}
