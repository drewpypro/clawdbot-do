###############################################################################
# DigitalOcean Project — organizes resources in the DO dashboard
###############################################################################
resource "digitalocean_project" "main" {
  name        = var.project_name
  description = "Managed by Terraform — ${var.project_name}"
  purpose     = "Service or API"
  environment = var.environment == "prod" ? "Production" : "Development"

  resources = concat(
    [for d in digitalocean_droplet.main : d.urn],
  )
}
