# clawdbot-do

DigitalOcean infrastructure managed with Terraform. Deploys droplets, VPC, firewall, and project resources with CI/CD via GitHub Actions.

## Architecture

```
┌─────────────────────────────────────┐
│        DigitalOcean Project         │
│         (clawdbot-do)               │
│                                     │
│  ┌───────────────────────────────┐  │
│  │           VPC                 │  │
│  │      10.10.10.0/24            │  │
│  │                               │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │     Droplet(s)          │  │  │
│  │  │  - Debian 13            │  │  │
│  │  │  - SSH key auth only    │  │  │
│  │  │  - fail2ban + UFW       │  │  │
│  │  │  - unattended-upgrades  │  │  │
│  │  └─────────────────────────┘  │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │        Firewall               │  │
│  │  IN:  SSH (restricted CIDRs)  │  │
│  │       HTTP/HTTPS (0.0.0.0/0)  │  │
│  │  OUT: All                     │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
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

## Security

- SSH key-only authentication (password auth disabled via userdata)
- DO firewall restricts SSH to specified CIDRs
- UFW as defense-in-depth on the droplet itself
- fail2ban for brute-force protection
- Automatic security updates via unattended-upgrades
- All secrets in GitHub Secrets, never in code

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
