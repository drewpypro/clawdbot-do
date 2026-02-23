# clawdbot-do

DigitalOcean infrastructure for the bogoylito fleet — containerized OpenClaw agents.

## Agents

| Agent | Model | Purpose | Channels |
|-------|-------|---------|----------|
| **bogoylito-chat** | Sonnet 4 | General chat bot | #bots, #bot_fight, #clawdbot-do |
| **bantay** | Opus 4 | Security monitoring | #bots, #security, #bot_fight, #clawdbot-do |

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
| `DISCORD_CHANNEL_CLAWDBOT_DO` | #clawdbot-do channel ID |

## Deploy (Phase 3)

```bash
# 1. Terraform apply (via GH Actions or manual)
# 2. SSH in
ssh -i ~/.ssh/clawdbot-do clawdbot@<droplet-ip>
cd ~/clawdbot-do

# 3. Create .env with secrets above (prepend space to keep out of bash_history)
 cat > .env << 'EOF'
ANTHROPIC_API_KEY=sk-ant-...
LITELLM_MASTER_KEY=sk-litellm-...
DISCORD_BOT_TOKEN_CHAT=...
DISCORD_BOT_TOKEN_SECURITY=...
DISCORD_GUILD_ID=...
DISCORD_CHANNEL_BOTS=...
DISCORD_CHANNEL_SECURITY=...
DISCORD_CHANNEL_BOTFIGHT=...
DISCORD_CHANNEL_CLAWDBOT_DO=...
EOF
chmod 600 .env

# 4. Start
docker compose build && docker compose up -d

# 5. Verify
docker compose ps
docker compose logs -f
```

## Operational Notes

- `docker compose restart` does NOT re-read `.env` — use `docker compose up -d` instead
- Config changes require volume wipe: `docker compose down <svc> && docker volume rm <vol> && docker compose up -d <svc>`
- `channels unresolved` warning at startup is benign (race condition, resolves after login)
- DO allows in-place CPU/RAM resize without destroying the droplet
- Prepend commands containing secrets with a space (`HISTCONTROL=ignoreboth`)
