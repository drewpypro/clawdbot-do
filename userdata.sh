#!/bin/bash
set -euo pipefail

LOG="/var/log/userdata.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Bootstrap started — $(date) ==="

###############################################################################
# System updates
###############################################################################
apt-get update -y
apt-get upgrade -y

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

systemctl enable fail2ban
systemctl start fail2ban

###############################################################################
# Create clawdbot user
###############################################################################
useradd -m -s /bin/bash clawdbot
usermod -aG docker clawdbot

###############################################################################
# Initialize Docker Swarm (single-node — for secrets support only)
###############################################################################
docker swarm init --advertise-addr 127.0.0.1 2>&1 || echo "Swarm already initialized"

###############################################################################
# Deploy stack directory
###############################################################################
DEPLOY_DIR="/home/clawdbot/bogoyito-stack"
mkdir -p "$DEPLOY_DIR"/{config,openclaw}

# --- docker-compose.yml ---
cat > "$DEPLOY_DIR/docker-compose.yml" << 'COMPOSE_EOF'
version: "3.9"

services:
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    ports:
      - "127.0.0.1:4000:4000"
    volumes:
      - ./config/litellm.yaml:/app/config.yaml:ro
    secrets:
      - anthropic_api_key
      - litellm_master_key
    environment:
      - ANTHROPIC_API_KEY_FILE=/run/secrets/anthropic_api_key
      - LITELLM_MASTER_KEY_FILE=/run/secrets/litellm_master_key
    command: ["--config", "/app/config.yaml", "--port", "4000", "--host", "0.0.0.0"]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    deploy:
      restart_policy:
        condition: any
        delay: 10s

  bogoyito-chat:
    image: bogoyito:latest
    depends_on:
      - litellm
    volumes:
      - ./config/chat.json:/home/clawdbot/.openclaw/config.json:ro
      - bogoyito-chat-data:/home/clawdbot/.openclaw/workspace
    secrets:
      - discord_bot_token
    environment:
      - OPENCLAW_CONFIG=/home/clawdbot/.openclaw/config.json
      - DISCORD_BOT_TOKEN_FILE=/run/secrets/discord_bot_token
    deploy:
      restart_policy:
        condition: any
        delay: 10s

  bogoyito-security:
    image: bogoyito:latest
    depends_on:
      - litellm
    volumes:
      - ./config/security.json:/home/clawdbot/.openclaw/config.json:ro
      - bogoyito-security-data:/home/clawdbot/.openclaw/workspace
    secrets:
      - discord_bot_token
    environment:
      - OPENCLAW_CONFIG=/home/clawdbot/.openclaw/config.json
      - DISCORD_BOT_TOKEN_FILE=/run/secrets/discord_bot_token
    deploy:
      restart_policy:
        condition: any
        delay: 10s

secrets:
  anthropic_api_key:
    external: true
  litellm_master_key:
    external: true
  discord_bot_token:
    external: true

volumes:
  bogoyito-chat-data:
  bogoyito-security-data:
COMPOSE_EOF

# --- Dockerfile ---
cat > "$DEPLOY_DIR/openclaw/Dockerfile" << 'DOCKER_EOF'
FROM node:22-slim

RUN useradd -m -s /bin/bash clawdbot && \
    npm install -g openclaw && \
    mkdir -p /home/clawdbot/.openclaw/workspace && \
    chown -R clawdbot:clawdbot /home/clawdbot

USER clawdbot
WORKDIR /home/clawdbot

CMD ["openclaw", "gateway", "start", "--foreground"]
DOCKER_EOF

# --- LiteLLM config ---
cat > "$DEPLOY_DIR/config/litellm.yaml" << 'LITELLM_EOF'
model_list:
  - model_name: claude-opus
    litellm_params:
      model: anthropic/claude-opus-4-6
      api_key: "os.environ/ANTHROPIC_API_KEY"

  - model_name: claude-sonnet
    litellm_params:
      model: anthropic/claude-sonnet-4-20250514
      api_key: "os.environ/ANTHROPIC_API_KEY"

general_settings:
  master_key: "os.environ/LITELLM_MASTER_KEY"

litellm_settings:
  drop_params: true
  set_verbose: false
LITELLM_EOF

# --- Agent configs ---
cat > "$DEPLOY_DIR/config/chat.json" << 'CHAT_EOF'
{
  "$schema": "https://docs.openclaw.ai/config-schema.json",
  "_comment": "Bogoyito Chat Agent — Discord social bot",
  "model": "claude-sonnet",
  "baseUrl": "http://litellm:4000",
  "channels": {
    "discord": {
      "enabled": true
    }
  }
}
CHAT_EOF

cat > "$DEPLOY_DIR/config/security.json" << 'SEC_EOF'
{
  "$schema": "https://docs.openclaw.ai/config-schema.json",
  "_comment": "Bogoyito Security Agent — vuln alerts and monitoring",
  "model": "claude-sonnet",
  "baseUrl": "http://litellm:4000",
  "channels": {
    "discord": {
      "enabled": true
    }
  }
}
SEC_EOF

# --- Build the OpenClaw image ---
cd "$DEPLOY_DIR"
docker build -t bogoyito:latest ./openclaw 2>&1 || echo "Docker build failed — will retry on deploy"

###############################################################################
# MOTD Banner
###############################################################################
cat > /etc/motd << 'BANNER_EOF'

  ____                         _ _        
 | __ )  ___   __ _  ___  _  _(_) |_ ___  
 |  _ \ / _ \ / _` |/ _ \| || | |  _/ _ \ 
 | |_) | (_) | (_| | (_) | || | | || (_) |
 |____/ \___/ \__, |\___/ \_, |_|\__\___/ 
              |___/       |__/            

  Remote Bogoyito Stack — DigitalOcean

  Stack:    /home/clawdbot/bogoyito-stack
  Setup:    su - clawdbot && cat ~/SETUP.md
  Secrets:  docker secret ls
  Services: docker stack services bogoyito

  Secrets are injected via GitHub Actions pipeline.
  No API keys are stored on disk.

BANNER_EOF

###############################################################################
# Post-deploy instructions
###############################################################################
cat > /home/clawdbot/SETUP.md << 'SETUP_EOF'
# Bogoyito Stack — Post-Deployment Setup

## Architecture
Secrets flow: GitHub Secrets → SSH pipeline → Docker Swarm (encrypted Raft)
Containers read secrets from /run/secrets/* (tmpfs, never on disk)

## 1. Verify Swarm is running
```bash
docker node ls
```

## 2. Inject secrets (via GitHub Actions)
Run the "Deploy Secrets" workflow from GitHub Actions.
It will SSH in and create Docker secrets + deploy the stack.

Or manually (for testing):
```bash
echo "sk-ant-..." | docker secret create anthropic_api_key -
echo "sk-litellm-..." | docker secret create litellm_master_key -
echo "discord-token..." | docker secret create discord_bot_token -
```

## 3. Deploy the stack
```bash
cd ~/bogoyito-stack
docker stack deploy -c docker-compose.yml bogoyito
```

## 4. Verify
```bash
docker stack services bogoyito
docker secret ls
docker service logs bogoyito_litellm
docker service logs bogoyito_bogoyito-chat
curl http://localhost:4000/health
```

## Commands
```bash
docker stack services bogoyito     # Service status
docker stack ps bogoyito           # Task status
docker service logs -f <service>   # Stream logs
docker stack rm bogoyito           # Tear down
docker stack deploy -c docker-compose.yml bogoyito  # Redeploy
```

## Secret Rotation
Run "Deploy Secrets" workflow with rotate=true, or manually:
```bash
docker secret rm anthropic_api_key
echo "new-key" | docker secret create anthropic_api_key -
docker service update --force bogoyito_litellm
```
SETUP_EOF

chown -R clawdbot:clawdbot /home/clawdbot/

echo "=== Bootstrap complete — $(date) ==="
echo "Swarm initialized. Run 'Deploy Secrets' workflow to inject keys and start stack."
