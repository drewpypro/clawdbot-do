#!/bin/bash
set -euo pipefail

# =============================================================================
# Docker Secrets → Environment Variable Bridge
# =============================================================================
# Docker Swarm mounts secrets as files in /run/secrets/. Neither LiteLLM nor
# OpenClaw support the _FILE env var convention, so this script reads each
# secret file and exports it as an uppercase environment variable.
#
# Example: /run/secrets/anthropic_api_key → ANTHROPIC_API_KEY
#
# This runs before the main process, so the app sees normal env vars.
# Secrets never touch disk — /run/secrets/ is tmpfs (RAM only).
# =============================================================================

if [ -d /run/secrets ]; then
  for secret_file in /run/secrets/*; do
    if [ -f "$secret_file" ]; then
      secret_name=$(basename "$secret_file")
      env_name=$(echo "$secret_name" | tr '[:lower:]' '[:upper:]')
      export "$env_name"="$(cat "$secret_file")"
    fi
  done
fi

exec "$@"
