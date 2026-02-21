# clawdbot-do

DigitalOcean infrastructure for Bogoyito — containerized OpenClaw agents.

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

### Droplet `.env` (Phase 2 — manual, temporary)

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Anthropic API key for LiteLLM |
| `LITELLM_MASTER_KEY` | LiteLLM admin key (generate: `openssl rand -hex 32`) |
| `DISCORD_BOT_TOKEN_CHAT` | Discord bot token for bogoyito-chat |
| `DISCORD_GUILD_ID` | Discord server/guild ID |
| `DISCORD_CHANNEL_BOTS` | #bots channel ID |
| `DISCORD_CHANNEL_TEST` | Test channel ID |

## Deploy (Phase 2)

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
DISCORD_GUILD_ID=...
DISCORD_CHANNEL_BOTS=...
DISCORD_CHANNEL_TEST=...
EOF
chmod 600 .env

# 4. Start
docker compose build && docker compose up -d

# 5. Verify
curl http://localhost:4000/health
docker compose logs -f
```
