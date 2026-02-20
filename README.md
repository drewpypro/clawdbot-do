# clawdbot-do

DigitalOcean infrastructure for deploying a remote OpenClaw + LiteLLM instance. Full bootstrap — `terraform apply` gives you a hardened droplet ready to run a second Bogoy with multi-model support via LiteLLM proxy.

## Architecture

```
┌─────────────────────────────────────────────┐
│          DigitalOcean Project               │
│            (clawdbot-do)                    │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │              VPC                      │  │
│  │         10.10.10.0/24                 │  │
│  │                                       │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │         Droplet                 │  │  │
│  │  │                                 │  │  │
│  │  │  ┌──────────┐  ┌────────────┐  │  │  │
│  │  │  │ OpenClaw │  │  LiteLLM   │  │  │  │
│  │  │  │ Gateway  │  │  Proxy     │  │  │  │
│  │  │  │ :18789   │  │  :4000     │  │  │  │
│  │  │  └────┬─────┘  └─────┬──────┘  │  │  │
│  │  │       │              │          │  │  │
│  │  │       └──── Discord ─┘          │  │  │
│  │  │            Anthropic            │  │  │
│  │  │            OpenAI               │  │  │
│  │  │            Gemini               │  │  │
│  │  │            Ollama (local)       │  │  │
│  │  │                                 │  │  │
│  │  │  Security:                      │  │  │
│  │  │  - SSH key-only auth            │  │  │
│  │  │  - fail2ban + UFW               │  │  │
│  │  │  - unattended-upgrades          │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │           Firewall                    │  │
│  │  IN:  SSH only (restricted CIDRs)     │  │
│  │  OUT: HTTPS, HTTP, DNS, NTP, ICMP     │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Quick Start

```bash
# Clone
git clone https://github.com/drewpypro/clawdbot-do.git
cd clawdbot-do

# Configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply
```

## Files

| File | Purpose |
|------|---------|
| `providers.tf` | Terraform + DO provider config |
| `variables.tf` | All input variables with defaults |
| `droplet.tf` | Droplet + SSH key resources |
| `networking.tf` | VPC + firewall rules |
| `project.tf` | DO project for dashboard organization |
| `outputs.tf` | Useful outputs (IPs, IDs, SSH command) |
| `userdata.sh` | Cloud-init bootstrap script |
| `terraform.tfvars.example` | Example variable values |

## CI/CD Workflows

| Workflow | Trigger | Action |
|----------|---------|--------|
| `terraform-plan.yaml` | PR to main | Format check, validate, plan |
| `terraform-build.yaml` | Push to main | Apply (requires `production` environment) |
| `terraform-destroy.yaml` | Manual dispatch | Destroy (requires `destroy` environment + confirmation) |

### Required Secrets

- `DIGITALOCEAN_TOKEN` — DO API token
- `SSH_PUBLIC_KEY` — Public SSH key for droplet access
- `ALLOWED_SSH_CIDR` — Your IP CIDR for SSH access

### Required Environments

- `production` — For apply workflow (recommended: require reviewers)
- `destroy` — For destroy workflow (recommended: require reviewers)

## Post-Deploy Setup

After `terraform apply`:

```bash
ssh root@<droplet_ip>
su - clawdbot
cat ~/SETUP.md    # Follow the guide
```

1. Edit `~/.env_secrets` with API keys
2. Edit `~/.litellm/config.yaml` to enable models
3. Start LiteLLM: `sudo systemctl enable --now litellm`
4. Run `openclaw setup` → point to LiteLLM at `http://127.0.0.1:4000`
5. Start OpenClaw: `openclaw gateway install && openclaw gateway start`

## Security

- **No inbound web ports** — SSH only, restricted to specified CIDRs
- SSH key-only authentication (password auth disabled via userdata)
- DO firewall + UFW (defense in depth)
- fail2ban for brute-force protection
- Automatic security updates via unattended-upgrades
- Outbound restricted to HTTPS, HTTP, DNS, NTP (no arbitrary ports)
- LiteLLM binds to localhost only (127.0.0.1:4000)
- All secrets in `~/.env_secrets` (600 permissions), never in code

## Source

Patterns derived from existing DO implementations:
- `johnpshids/digital-ocean-drewplet` (Gitea) — VPC, firewall, droplet baseline
- `drewpypro/clawdbot-aws` (GitHub) — CI/CD workflows, branch protection patterns

## Cost Estimate

| Resource | Monthly Cost |
|----------|-------------|
| 1x s-1vcpu-1gb Droplet | ~$6 |
| VPC | Free |
| Firewall | Free |
| Monitoring | Free |
| **Total** | **~$6/mo** |

Costs scale with droplet size and count. See [DO pricing](https://www.digitalocean.com/pricing/droplets).
