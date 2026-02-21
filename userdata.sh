#!/bin/bash
set -euo pipefail
LOG="/var/log/userdata.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Bootstrap started — $(date) ==="

# --- System updates ---
apt-get update -y && apt-get upgrade -y
apt-get install -y \
  curl wget git vim htop jq \
  unattended-upgrades \
  ca-certificates gnupg \
  docker.io docker-compose-plugin

# --- Unattended upgrades ---
dpkg-reconfigure -plow unattended-upgrades

# --- SSH hardening ---
sed -i 's/#\?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#\?X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/#\?MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
systemctl restart sshd

# --- clawdbot user ---
useradd -m -s /bin/bash clawdbot
usermod -aG docker clawdbot

echo "=== Bootstrap complete — $(date) ==="
