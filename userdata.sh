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
  ca-certificates gnupg

# --- Docker (official repo) ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- Unattended upgrades ---
dpkg-reconfigure -plow unattended-upgrades

# --- SSH hardening ---
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
systemctl restart sshd

# --- clawdbot user ---
useradd -m -s /bin/bash clawdbot
usermod -aG docker clawdbot

echo "=== Bootstrap complete — $(date) ==="
