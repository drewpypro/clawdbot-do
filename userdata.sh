#!/bin/bash
set -euo pipefail

###############################################################################
# Droplet Bootstrap — full OpenClaw + LiteLLM deployment
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
  unattended-upgrades \
  ca-certificates \
  gnupg \
  jq \
  docker.io \
  docker-compose

# Enable automatic security updates
dpkg-reconfigure -plow unattended-upgrades

###############################################################################
# SSH Hardening
###############################################################################
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config
systemctl restart sshd

###############################################################################
# UFW (defense in depth — DO firewall is primary)
###############################################################################
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw --force enable

# Enable fail2ban
systemctl enable fail2ban
systemctl start fail2ban

###############################################################################
# Create clawdbot user
###############################################################################
useradd -m -s /bin/bash clawdbot
usermod -aG docker clawdbot

###############################################################################
# Install Node.js (LTS)
###############################################################################
su - clawdbot -c '
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
'

###############################################################################
# Install OpenClaw
###############################################################################
su - clawdbot -c '
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npm install -g openclaw
'

###############################################################################
# Install LiteLLM Proxy
###############################################################################
apt-get install -y python3 python3-pip python3-venv

su - clawdbot -c '
  python3 -m venv ~/litellm-env
  ~/litellm-env/bin/pip install "litellm[proxy]"
'

# Create LiteLLM config directory
su - clawdbot -c 'mkdir -p ~/.litellm'

# Create placeholder LiteLLM config
# User must populate API keys after deployment
cat > /home/clawdbot/.litellm/config.yaml << 'LITELLM_EOF'
# LiteLLM Proxy Configuration
# Add your model API keys below after deployment
# Docs: https://docs.litellm.ai/docs/proxy/configs

model_list:
  # Anthropic (primary)
  - model_name: claude-opus
    litellm_params:
      model: anthropic/claude-opus-4-6
      api_key: "os.environ/ANTHROPIC_API_KEY"

  # OpenAI (optional)
  # - model_name: gpt-4o
  #   litellm_params:
  #     model: openai/gpt-4o
  #     api_key: "os.environ/OPENAI_API_KEY"

  # Google Gemini (optional)
  # - model_name: gemini-pro
  #   litellm_params:
  #     model: gemini/gemini-1.5-pro
  #     api_key: "os.environ/GOOGLE_API_KEY"

  # Local Ollama (optional)
  # - model_name: local-llama
  #   litellm_params:
  #     model: ollama/llama3
  #     api_base: http://localhost:11434

general_settings:
  master_key: "os.environ/LITELLM_MASTER_KEY"
  database_url: null

litellm_settings:
  drop_params: true
  set_verbose: false
LITELLM_EOF

chown clawdbot:clawdbot /home/clawdbot/.litellm/config.yaml
chmod 600 /home/clawdbot/.litellm/config.yaml

###############################################################################
# Create systemd service for LiteLLM
###############################################################################
cat > /etc/systemd/system/litellm.service << 'SERVICE_EOF'
[Unit]
Description=LiteLLM Proxy
After=network.target

[Service]
Type=simple
User=clawdbot
WorkingDirectory=/home/clawdbot
EnvironmentFile=/home/clawdbot/.env_secrets
ExecStart=/home/clawdbot/litellm-env/bin/litellm --config /home/clawdbot/.litellm/config.yaml --port 4000 --host 127.0.0.1
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

###############################################################################
# Create placeholder secrets file
###############################################################################
cat > /home/clawdbot/.env_secrets << 'ENV_EOF'
# Populate these after deployment
# ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...
# GOOGLE_API_KEY=AI...
# LITELLM_MASTER_KEY=sk-litellm-...
# DISCORD_BOT_TOKEN=...
ENV_EOF

chown clawdbot:clawdbot /home/clawdbot/.env_secrets
chmod 600 /home/clawdbot/.env_secrets

###############################################################################
# Post-deploy instructions
###############################################################################
cat > /home/clawdbot/SETUP.md << 'SETUP_EOF'
# Post-Deployment Setup

## 1. Configure secrets
Edit ~/.env_secrets with your API keys

## 2. Start LiteLLM
sudo systemctl enable litellm
sudo systemctl start litellm

## 3. Configure OpenClaw
openclaw setup
# Point to LiteLLM proxy: http://127.0.0.1:4000
# Configure Discord bot token

## 4. Install and start OpenClaw gateway
openclaw gateway install
openclaw gateway start

## 5. Verify
openclaw status
curl http://127.0.0.1:4000/health
SETUP_EOF

chown clawdbot:clawdbot /home/clawdbot/SETUP.md

echo "Bootstrap complete — $(date)" >> /var/log/userdata.log
echo "Run 'su - clawdbot' then follow ~/SETUP.md" >> /var/log/userdata.log
