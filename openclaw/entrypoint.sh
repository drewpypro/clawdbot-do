#!/bin/bash
# Create required OpenClaw directories
mkdir -p /home/clawdbot/.openclaw/agents/main/sessions \
         /home/clawdbot/.openclaw/credentials \
         /home/clawdbot/.openclaw/workspace
chmod 700 /home/clawdbot/.openclaw

# Copy config template and substitute env vars on first run only
if [ -f /config/openclaw.json ] && [ ! -f /home/clawdbot/.openclaw/openclaw.json ]; then
  node -e "
    const fs = require('fs');
    let config = fs.readFileSync('/config/openclaw.json', 'utf8');
    config = config.replace(/\\\$\{(\w+)\}/g, (_, k) => process.env[k] || '');
    fs.writeFileSync('/home/clawdbot/.openclaw/openclaw.json', config);
  " || cp /config/openclaw.json /home/clawdbot/.openclaw/openclaw.json
fi

# Copy default workspace files on first run only
if [ -d /defaults/workspace ] && [ ! -f /home/clawdbot/.openclaw/workspace/IDENTITY.md ]; then
  cp -rn /defaults/workspace/* /home/clawdbot/.openclaw/workspace/ 2>/dev/null || true
fi

exec openclaw gateway run
