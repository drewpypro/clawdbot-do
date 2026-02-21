#!/bin/bash
set -euo pipefail
LOG="/var/log/userdata.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Bootstrap started — $(date) ==="
export DEBIAN_FRONTEND=noninteractive

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
# Allow both root (for now) and clawdbot
grep -q '^AllowUsers' /etc/ssh/sshd_config || echo "AllowUsers root clawdbot" >> /etc/ssh/sshd_config
systemctl restart sshd

# --- clawdbot user ---
useradd -m -s /bin/bash clawdbot
usermod -aG docker clawdbot

# --- Propagate SSH key to clawdbot user ---
mkdir -p /home/clawdbot/.ssh
cp /root/.ssh/authorized_keys /home/clawdbot/.ssh/authorized_keys
chown -R clawdbot:clawdbot /home/clawdbot/.ssh
chmod 700 /home/clawdbot/.ssh
chmod 600 /home/clawdbot/.ssh/authorized_keys

# --- Clone repo for app-layer config ---
su - clawdbot -c "git clone https://github.com/drewpypro/clawdbot-do.git /home/clawdbot/clawdbot-do"

# --- Custom MOTD ---
cat > /etc/motd << 'MOTD'

  ╔══════════════════════════════════════╗
  ║                                      ║
  ║   (o_O)  BOGOYITO ONLINE             ║
  ║   <| |>  DO Agent Node               ║
  ║    / \   drewpypro/clawdbot-do       ║
  ║                                      ║
  ╚══════════════════════════════════════╝

MOTD

echo "=== Bootstrap complete — $(date) ==="
