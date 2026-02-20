#!/bin/bash
set -euo pipefail

###############################################################################
# Droplet Bootstrap — runs on first boot via cloud-init
###############################################################################

# System updates
apt-get update -y
apt-get upgrade -y

# Essential packages
apt-get install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  ufw \
  fail2ban \
  unattended-upgrades

# Enable automatic security updates
dpkg-reconfigure -plow unattended-upgrades

# Harden SSH
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
systemctl restart sshd

# Configure UFW (DigitalOcean firewall is primary, this is defense in depth)
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw --force enable

# Enable fail2ban
systemctl enable fail2ban
systemctl start fail2ban

echo "Bootstrap complete — $(date)" >> /var/log/userdata.log
