#!/bin/bash
# Copy config template so OpenClaw can write to it (bind-mount single files don't support atomic rename)
if [ -f /config/openclaw.json ]; then
  cp /config/openclaw.json /home/clawdbot/.openclaw/openclaw.json
fi
exec openclaw gateway run
