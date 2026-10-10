# openclaw-proxmox

**Self-host OpenClaw inside Docker on an Ubuntu 24.04 Proxmox VM using OpenTofu + Ansible.**

Designed as a reusable, public infrastructure-as-code example: clear ownership of infrastructure, guest configuration, application state, and day-two operations. **Cloudflare Tunnel is intentionally manual and never provisioned or stored by this repository.**

> Status: deployment starter validated statically, **not** deployed to a live Proxmox host or authenticated against a ChatGPT Plus account. Review settings and perform the documented validation before production use.

## What gets deployed?

```text
Windows 11 -> WSL2 Ubuntu (or native Linux terminal)
     | 
     +-- OpenTofu ----> Proxmox API ----> Ubuntu 24.04 VM, openclaw-01
     +-- Ansible -------------- SSH ----> Docker Engine + Compose
                                        |
                                        +--> OpenClaw gateway container
                                             local bind 127.0.0.1:18789
                                             persistent /srv/openclaw/

MANUALLY, outside this repository:
Cloudflare DNS + Tunnel + Access -> cloudflared (installed manually on VM)
                                    -> http://127.0.0.1:18789
                                    -> OpenClaw UI
```

**No tunnel token, Cloudflare API token, or Cloudflare resources are part of the automated deployment.** OpenClaw receives a *separate* randomly generated Gateway authentication token, stored on the VM in `/opt/openclaw/.env` and never committed.

## Example configuration (generic placeholders only)

| Item | Default |
| --- | --- |
| Repository | `openclaw-proxmox` |
| VM | `openclaw-01`, VMID `2100` (change if in use) |
| Template | `9000` (Ubuntu 24.04 cloud-init; existing template required) |
| VM resources | 4 vCPU / 8 GiB RAM / 64 GiB disk |
| Linux account | `ubuntu` |
| Application | `/opt/openclaw` |
| Persisted OpenClaw data | `/srv/openclaw` |
| Docker image | Official `ghcr.io/openclaw/openclaw:latest` (pin after validation) |
| Local web port | `127.0.0.1:18789` **only** |
| Cloudflare hostname example | `openclaw.example.com` (**replace with your own domain in ignored local settings**) |
| Cloudflare tunnel | **Manually installed and managed by operator** |
| AI authentication | **Manually connect ChatGPT/Codex via OAuth after deployment** |

## Start here

**PUBLIC REPOSITORY NOTE:** Example domains use reserved `example.com`; IP addresses use RFC 5737 documentation ranges. Do not substitute real infrastructure addresses or credentials into tracked files. All local deployment customization belongs in ignored files.

**Before deploying:** Copy `ansible/group_vars/local.yml.example` to the ignored `ansible/group_vars/local.yml` and replace the reserved example hostname with your own if using a public DNS name. The committed hostname, IPs, VM IDs, and usernames are examples, not values tied to any deployment.

1. **Windows:** [Windows 11 + WSL2 walkthrough](docs/windows-wsl.md). **Linux:** [Linux workstation walkthrough](docs/linux.md).
2. Create your own SSH key: [SSH key and permissions guide](docs/ssh.md).
3. Prepare a functioning Ubuntu 24.04 Proxmox cloud-init template, created separately for your environment: [Proxmox prerequisites](docs/proxmox.md).
4. Follow the entire [step-by-step deployment guide](docs/deploy.md).
5. Connect ChatGPT Plus, verify an actual completion, and select a model you can access: [ChatGPT Plus / model guide](docs/chatgpt-plus.md).
6. **Separately and manually** configure your domain, Cloudflare Tunnel and Access: [Cloudflare Tunnel](docs/cloudflare-manual.md).
7. Learn [automations](docs/automations.md), [GitHub access](docs/github.md), and [operations](docs/operations.md).

## Quick reference (after prerequisites)

Run all controller commands inside **WSL Ubuntu or native Linux**, not PowerShell or Windows CMD.

```bash
cd ~/projects/openclaw-proxmox
# Set up a unique VM key; see docs/ssh.md first.
cp opentofu/terraform.tfvars.example opentofu/terraform.tfvars
nano opentofu/terraform.tfvars
read -r -s -p 'Proxmox API token: ' PROXMOX_VE_API_TOKEN; echo
export PROXMOX_VE_API_TOKEN
cd opentofu
tofu init
tofu fmt -check
tofu validate
tofu plan -out=openclaw.tfplan
tofu apply openclaw.tfplan
cd ../ansible
ansible-galaxy collection install -r requirements.yml
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible -i inventory/hosts.ini openclaw -m ping
ansible-playbook -i inventory/hosts.ini site.yml
```

The hidden-input prompt avoids placing the Proxmox token directly in shell history. Avoid sharing your terminal session or logs. Make sure your PVE API role can clone and configure the VM/storage, including `Datastore.AllocateSpace`; see [Proxmox prerequisites](docs/proxmox.md).

Before publishing, run `python3 scripts/public-audit.py` and review [publication checklist](docs/publish.md). The audit does not replace manual review.

## Operating model

- **OpenTofu:** creates only the Proxmox guest, configures cloud-init network/user/SSH and writes a local ignored Ansible inventory. It does not install applications or touch Cloudflare.
- **Ansible:** installs Docker Engine, Compose, persistent directories and OpenClaw; creates a token once and initializes a baseline config once. Re-running the playbook preserves OAuth, Gateway state, workspaces, and scheduling data.
- **OpenClaw:** the actual application, including its built-in automation scheduler. Complete provider authorization separately using the official CLI.
- **Cloudflare:** a completely independent manual connector, external hostname route and Cloudflare Access policy. You can build and test the app via an SSH tunnel before enabling public DNS.

## Documentation index

| Document | Purpose |
| --- | --- |
| [Architecture](docs/architecture.md) | boundaries, service isolation, data persistence |
| [Windows + WSL](docs/windows-wsl.md) | install WSL2, package managers, OpenTofu, Ansible, SSH |
| [Linux](docs/linux.md) | Linux workstation install and tools |
| [SSH keys](docs/ssh.md) | unique Ed25519 key, secure permissions, first host trust |
| [Proxmox](docs/proxmox.md) | template, API token/RBAC, networking, resources |
| [Deployment](docs/deploy.md) | start to finish commands and expected checks |
| [ChatGPT Plus](docs/chatgpt-plus.md) | device-code login, token vs OAuth, models, troubleshooting |
| [Cloudflare](docs/cloudflare-manual.md) | **manual** DNS, Tunnel, Access, no tokens in IaC |
| [GitHub](docs/github.md) | scoped authentication and repository work |
| [Automation](docs/automations.md) | built-in scheduler, safety, test jobs |
| [Operations](docs/operations.md) | logs, backup, restore, upgrades, reboots |
| [Security](docs/security.md) | risk boundaries, Access, permissions, public repo checklist |
| [Troubleshooting](docs/troubleshooting.md) | common WSL, Ansible, Proxmox, Docker, OAuth errors |
| [Validation checklist](docs/validation.md) | local static tests and real-world smoke tests |
| [Publish to GitHub](docs/publish.md) | safely initialize and push the new repository |

## Repository layout

```text
openclaw-proxmox/
├── README.md
├── CONTRIBUTING.md
├── LICENSE
├── Makefile
├── .gitignore
├── .github/workflows/validate.yml
├── opentofu/
│   ├── versions.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── ansible/
│   ├── ansible.cfg
│   ├── requirements.yml
│   ├── inventory/hosts.ini.example
│   ├── group_vars/all.yml
│   ├── group_vars/local.yml.example
│   ├── templates/compose.yml.j2
│   └── site.yml
├── scripts/
│   ├── verify-local.sh
│   ├── check-guest.sh
│   ├── backup-guest.sh
│   └── restore-guest.sh
└── docs/
```

## What this does NOT do

- No Cloudflare Tunnel creation, installation, service management, API interaction, or token storage.
- No automatic public network exposure or firewall port forwarding.
- No unattended ChatGPT OAuth login (requires your deliberate authentication).
- No default GitHub credential or access to your repositories (you decide and grant permissions).
- No guarantee that the exact GPT model seen in OpenCode is available in OpenClaw. Test an actual completion first.
- No automatic VM destruction: `tofu destroy` is an explicit, destructive operator action.

## Upstream references

- [OpenClaw Docker deployment](https://docs.openclaw.ai/install/docker)
- [OpenClaw OpenAI authentication](https://docs.openclaw.ai/providers/openai/setup)
- [OpenClaw automations](https://docs.openclaw.ai/cli/cron)
- [Cloudflare manually managed tunnels](https://developers.cloudflare.com/tunnel/get-started/)
- [bpg/proxmox OpenTofu provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

Licensed under MIT. See [CONTRIBUTING.md](CONTRIBUTING.md) for development expectations.
