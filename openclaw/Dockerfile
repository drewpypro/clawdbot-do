FROM node:22-slim

RUN useradd -m -s /bin/bash clawdbot && \
    npm install -g openclaw && \
    mkdir -p /home/clawdbot/.openclaw/workspace && \
    chown -R clawdbot:clawdbot /home/clawdbot

USER clawdbot
WORKDIR /home/clawdbot

CMD ["openclaw", "gateway", "start", "--foreground"]
