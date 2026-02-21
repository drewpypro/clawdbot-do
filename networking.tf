# =============================================================================
# Networking - VPC (existing) + Firewall
# =============================================================================

# --- Use existing default VPC in sfo2 ---
data "digitalocean_vpc" "default" {
  region = var.do_region
}

# --- Cloud Firewall ---
resource "digitalocean_firewall" "clawdbot" {
  name        = "clawdbot-fw"
  droplet_ids = [digitalocean_droplet.clawdbot.id]

  # --- Ingress: SSH from allowed CIDRs ---
  dynamic "inbound_rule" {
    for_each = var.allowed_ssh_cidrs
    content {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = [inbound_rule.value]
    }
  }

  # --- Ingress: ICMP from allowed CIDRs ---
  dynamic "inbound_rule" {
    for_each = var.allowed_ssh_cidrs
    content {
      protocol         = "icmp"
      source_addresses = [inbound_rule.value]
    }
  }

  # --- Egress: HTTPS ---
  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # --- Egress: HTTP (apt repos, OCSP) ---
  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # --- Egress: DNS ---
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

  # --- Egress: NTP ---
  outbound_rule {
    protocol              = "udp"
    port_range            = "123"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  # --- Egress: ICMP ---
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
