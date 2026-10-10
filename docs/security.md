# Security and public-repository publishing checklist

An autonomous coding agent is security-sensitive: it can process untrusted text, call tools and perhaps execute shell commands. The default posture deliberately restricts incoming traffic, credentials, and scope.

## Default safety controls

- VM contains OpenClaw: no Docker on the Proxmox host.
- Host publishes `127.0.0.1:18789:18789` (not `0.0.0.0`).
- Gateway requires a randomly generated token stored 0600 on VM.
- SSH uses its own Ed25519 key, and Ansible leaves host-key checking enabled.
- Cloudflare Tunnel is a separate **manual** task; `cloudflared` is NOT in Compose or Ansible.
- The Cloudflare hostname must be protected by **Cloudflare Access** with a restrictive identity Allow policy.
- Container drops `NET_RAW`, `NET_ADMIN` and disables new privileges.
- No Docker host socket mount; no Proxmox admin secret available to the container.
- Agent GitHub write permission is not configured by default.
- App and auth state persist across redeploys; backups are classified as secrets.

## Limitations and important nuance

The Docker container is **not** equivalent to a security sandbox for arbitrary malicious code, especially if you later mount credentials, GitHub workspaces, system sockets, or host directories. OpenClaw's agent-level tool/execution approval settings and sandbox configuration should be reviewed before enabling unattended risky commands. This starter doesn't enable complex sandbox infrastructure automatically; configure it deliberately after onboarding and test it first.

Docker group membership grants powerful access to the Linux host. Anyone who can control the `ubuntu` account or unrestricted OpenClaw exec tools could compromise the dedicated VM. Use this VM for agent tasks only; avoid mounting personal documents, Proxmox API credentials, backup storage, or SSH private keys for unrelated services.

Cloudflare Tunnel makes a network path; **it does not authenticate users on its own**. Use Cloudflare Access *and* the OpenClaw gateway token/pairing. Keep the Access app restricted even when a provider's OAuth works.

## Before a public Git push

```bash
cd ~/projects/openclaw-proxmox
git status --short
git ls-files | sort
# Investigate any tracked secrets or generated files:
git ls-files | grep -E '(^|/)(\.env$|terraform\.tfvars$|terraform\.tfstate|hosts\.ini$|.*vault.*\.yml$|.*\.pem$|id_ed25519)' || true
# Search for obvious accidental token strings and replace/rotate if found:
grep -RInE --exclude-dir=.git '(sk-[A-Za-z0-9]{16,}|ghp_[A-Za-z0-9]{16,}|OPENCLAW_GATEWAY_TOKEN=[a-f0-9]{64})' README.md docs ansible opentofu scripts || true
```

Only examples should be tracked. `opentofu/terraform.tfvars`, `ansible/inventory/hosts.ini`, `.env`, `tfstate`, private keys, auth profile secrets, and backups are ignored. Be aware `.gitignore` does not protect a file previously committed; remove it from Git history and revoke any credential exposed.

## Token management

| Token | Holder | Source |
| --- | --- | --- |
| Proxmox API | Controller shell only | Manually created Proxmox token |
| VM SSH private key | WSL/Linux `~/.ssh` only | `ssh-keygen` |
| OpenClaw Gateway token | VM `/opt/openclaw/.env` | Ansible-generated once |
| ChatGPT OAuth credentials | VM persistent app state | Interactive OpenClaw login |
| Cloudflare Tunnel token | Cloudflare-managed connector service on VM | **Manual Cloudflare dashboard** |
| GitHub write credential | Optional VM-persisted gh profile | Explicit user authorization only |

Never share these tokens or ask an autonomous coding agent to print them. Restrict who can read VM backups and logs.
