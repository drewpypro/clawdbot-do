# =============================================================================
# Variables - Clawdbot DO Deployment
# =============================================================================

variable "do_region" {
  type        = string
  description = "DigitalOcean region"
  default     = "sfo2"
}

variable "droplet_size" {
  type        = string
  description = "Droplet size slug"
  default     = "s-1vcpu-2gb"
}

variable "droplet_image" {
  type        = string
  description = "Droplet OS image slug"
  default     = "debian-13-x64"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for droplet access"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH into the droplet"
  default     = []
}
