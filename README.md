# clawdbot-do

DigitalOcean infrastructure for the bogoylito fleet — containerized OpenClaw agents.

## Agents

| Agent | Model | Purpose | Channel |
|-------|-------|---------|---------|
| **bogoylito-chat** | Sonnet 4 | General chat bot | #bots, #bot_fight |
| **bantay** | Opus 4 | Security monitoring | #security, #bot_fight |

## Required Secrets

### GitHub Actions (Terraform)

| Secret | Purpose |
|--------|---------|
| `DIGITALOCEAN_TOKEN` | DO API token |
| `SSH_PUBLIC_KEY` | Injected into droplet |
| `ALLOWED_SSH_CIDRS` | SSH access CIDRs (JSON list) |
| `BUCKET_NAME` | R2/Spaces state bucket |
| `BUCKET_KEY` | State file key |
| `BUCKET_ENDPOINT` | Spaces/R2 endpoint |
| `BUCKET_ACCESS_KEY_ID` | Spaces/R2 access key |
| `BUCKET_SECRET_ACCESS_KEY` | Spaces/R2 secret key |

### Droplet `.env` (Phase 2-3 — manual, temporary)

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Anthropic API key for LiteLLM |
| `LITELLM_MASTER_KEY` | LiteLLM admin key (generate: `openssl rand -hex 32`) |
| `DISCORD_BOT_TOKEN_CHAT` | Discord bot token for bogoylito-chat |
| `DISCORD_BOT_TOKEN_SECURITY` | Discord bot token for bantay |
| `DISCORD_GUILD_ID` | Discord server/guild ID |
| `DISCORD_CHANNEL_BOTS` | #bots channel ID |
| `DISCORD_CHANNEL_SECURITY` | #security channel ID |
| `DISCORD_CHANNEL_BOTFIGHT` | #bot_fight channel ID |

## Deploy (Phase 3)

```bash
# 1. Terraform apply (via GH Actions or manual)
# 2. SSH in
ssh -i ~/.ssh/clawdbot-do clawdbot@<droplet-ip>
cd ~/clawdbot-do

# 3. Create .env with secrets above
cat > .env << 'EOF'
ANTHROPIC_API_KEY=sk-ant-...
LITELLM_MASTER_KEY=sk-litellm-...
DISCORD_BOT_TOKEN_CHAT=...
DISCORD_BOT_TOKEN_SECURITY=...
DISCORD_GUILD_ID=...
DISCORD_CHANNEL_BOTS=...
DISCORD_CHANNEL_SECURITY=...
DISCORD_CHANNEL_BOTFIGHT=...
EOF
chmod 600 .env

# 4. Start
docker compose build && docker compose up -d

# 5. Verify
curl http://localhost:4000/health
docker compose logs -f
```
