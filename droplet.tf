# =============================================================================
# Droplet - Clawdbot (OpenClaw AI Assistant)
# =============================================================================

# --- SSH Key ---
resource "digitalocean_ssh_key" "clawdbot" {
  name       = "clawdbot-key"
  public_key = var.ssh_public_key
}

# --- Droplet ---
resource "digitalocean_droplet" "clawdbot" {
  name     = "clawdbot"
  image    = var.droplet_image
  size     = var.droplet_size
  region   = var.do_region
  vpc_uuid = data.digitalocean_vpc.default.id

  ssh_keys = [digitalocean_ssh_key.clawdbot.fingerprint]

  user_data = file("${path.module}/userdata.sh")

  lifecycle {
    ignore_changes = [image]
  }
}
