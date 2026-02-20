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

  # HTTP/HTTPS inbound (optional — remove if not needed)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # ICMP (ping)
  inbound_rule {
    protocol         = "icmp"
    source_addresses = var.allowed_ssh_cidrs
  }

  # All outbound
  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  depends_on = [digitalocean_droplet.main]
}
