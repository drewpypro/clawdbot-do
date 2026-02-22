FROM node:22-slim

RUN apt-get update && apt-get install -y curl git python3 build-essential && rm -rf /var/lib/apt/lists/* && \
    useradd -m -s /bin/bash clawdbot && \
    npm install -g openclaw && \
    mkdir -p /home/clawdbot/.openclaw/workspace && \
    chown -R clawdbot:clawdbot /home/clawdbot

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

USER clawdbot
WORKDIR /home/clawdbot

ENTRYPOINT ["entrypoint.sh"]
