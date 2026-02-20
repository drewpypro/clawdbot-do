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
# Deploy Docker Compose stack
###############################################################################
DEPLOY_DIR="/home/clawdbot/bogoyito-stack"
mkdir -p "$DEPLOY_DIR"/{config,openclaw}

# --- docker-compose.yml ---
cat > "$DEPLOY_DIR/docker-compose.yml" << 'COMPOSE_EOF'
services:
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    container_name: litellm
    restart: unless-stopped
    ports:
      - "127.0.0.1:4000:4000"
    volumes:
      - ./config/litellm.yaml:/app/config.yaml:ro
    env_file:
      - .env
    command: ["--config", "/app/config.yaml", "--port", "4000", "--host", "0.0.0.0"]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s

  bogoyito-chat:
    build:
      context: ./openclaw
      dockerfile: Dockerfile
    container_name: bogoyito-chat
    restart: unless-stopped
    depends_on:
      litellm:
        condition: service_healthy
    volumes:
      - ./config/chat.json:/home/clawdbot/.openclaw/config.json:ro
      - bogoyito-chat-data:/home/clawdbot/.openclaw/workspace
    env_file:
      - .env
    environment:
      - OPENCLAW_CONFIG=/home/clawdbot/.openclaw/config.json

  bogoyito-security:
    build:
      context: ./openclaw
      dockerfile: Dockerfile
    container_name: bogoyito-security
    restart: unless-stopped
    depends_on:
      litellm:
        condition: service_healthy
    volumes:
      - ./config/security.json:/home/clawdbot/.openclaw/config.json:ro
      - bogoyito-security-data:/home/clawdbot/.openclaw/workspace
    env_file:
      - .env
    environment:
      - OPENCLAW_CONFIG=/home/clawdbot/.openclaw/config.json

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

  # Uncomment when keys are set:
  # - model_name: gpt-4o
  #   litellm_params:
  #     model: openai/gpt-4o
  #     api_key: "os.environ/OPENAI_API_KEY"
  # - model_name: gemini-pro
  #   litellm_params:
  #     model: gemini/gemini-2.5-pro
  #     api_key: "os.environ/GOOGLE_API_KEY"

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

# --- .env placeholder ---
cat > "$DEPLOY_DIR/.env" << 'ENV_EOF'
# Populate these after deployment
# ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...
# GOOGLE_API_KEY=AI...
LITELLM_MASTER_KEY=sk-litellm-changeme
# DISCORD_BOT_TOKEN=...
ENV_EOF

chmod 600 "$DEPLOY_DIR/.env"

# --- Pre-build the OpenClaw image ---
cd "$DEPLOY_DIR"
docker compose build 2>&1 || echo "Docker build failed — will retry on first 'up'"

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
  Status:   docker compose -f ~/bogoyito-stack/docker-compose.yml ps

BANNER_EOF

###############################################################################
# Post-deploy instructions
###############################################################################
cat > /home/clawdbot/SETUP.md << 'SETUP_EOF'
# Bogoyito Stack — Post-Deployment Setup

## 1. Configure secrets
```bash
cd ~/bogoyito-stack
vim .env
# Add your API keys (ANTHROPIC_API_KEY, DISCORD_BOT_TOKEN, etc.)
# Change LITELLM_MASTER_KEY to something secure
```

## 2. Review agent configs
```bash
ls config/
# litellm.yaml  — model routing (uncomment models as needed)
# chat.json     — Discord chat agent config
# security.json — Vuln alert agent config
```

## 3. Start the stack
```bash
docker compose up -d
```

## 4. Verify
```bash
docker compose ps
docker compose logs litellm    # Check LiteLLM is healthy
docker compose logs bogoyito-chat  # Check agent started
curl http://localhost:4000/health
```

## 5. Add a new agent
1. Create `config/newagent.json`
2. Add service to `docker-compose.yml` (see README)
3. `docker compose up -d bogoyito-newagent`

## Commands
```bash
docker compose ps              # Status
docker compose logs -f         # Stream all logs
docker compose restart         # Restart everything
docker compose down            # Stop everything
docker compose up -d           # Start everything
```
SETUP_EOF

chown -R clawdbot:clawdbot /home/clawdbot/

echo "=== Bootstrap complete — $(date) ==="
