###############################################################################
# SSH Key
###############################################################################
resource "digitalocean_ssh_key" "main" {
  name       = "${var.project_name}-${var.environment}-key"
  public_key = var.ssh_public_key
}

###############################################################################
# Droplet(s)
###############################################################################
resource "digitalocean_droplet" "main" {
  count = var.droplet_count

  name     = var.droplet_count > 1 ? "${var.droplet_name}-${var.environment}-${count.index + 1}" : "${var.droplet_name}-${var.environment}"
  region   = var.region
  size     = var.droplet_size
  image    = var.droplet_image
  vpc_uuid = digitalocean_vpc.main.id

  ssh_keys   = [digitalocean_ssh_key.main.id]
  backups    = var.enable_backups
  ipv6       = var.enable_ipv6
  monitoring = var.enable_monitoring

  user_data = file("${path.module}/userdata.sh")

  tags = [
    var.project_name,
    var.environment,
    "managed-by-terraform"
  ]

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    digitalocean_vpc.main,
    digitalocean_ssh_key.main
  ]
}
