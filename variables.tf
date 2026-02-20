###############################################################################
# Authentication
###############################################################################
variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

###############################################################################
# SSH
###############################################################################
variable "ssh_public_key" {
  description = "Public SSH key for droplet access"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to private SSH key for provisioner connections"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

###############################################################################
# Region & Sizing
###############################################################################
variable "region" {
  description = "DigitalOcean region (https://docs.digitalocean.com/platform/regional-availability/)"
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Droplet size slug (https://slugs.do-api.dev/)"
  type        = string
  default     = "s-1vcpu-1gb"
}

###############################################################################
# Networking
###############################################################################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.10.0/24"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into droplets"
  type        = list(string)
}

###############################################################################
# Droplet Configuration
###############################################################################
variable "droplet_image" {
  description = "Droplet image slug or custom image ID"
  type        = string
  default     = "debian-13-x64"
}

variable "droplet_name" {
  description = "Name prefix for droplets"
  type        = string
  default     = "clawdbot"
}

variable "droplet_count" {
  description = "Number of droplets to create"
  type        = number
  default     = 1
}

variable "enable_backups" {
  description = "Enable automated backups for droplets"
  type        = bool
  default     = false
}

variable "enable_ipv6" {
  description = "Enable IPv6 on droplets"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable DigitalOcean monitoring agent"
  type        = bool
  default     = true
}

###############################################################################
# Tags
###############################################################################
variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "clawdbot-do"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "dev"
}
