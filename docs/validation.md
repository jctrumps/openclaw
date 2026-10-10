# Validation checklist (before pushing to GitHub)

This project is a starter. Its files can be parsed locally, but **live Proxmox provisioning, Cloudflare Tunnel, ChatGPT OAuth, and agent runs require operator tests**. Check off each phase before calling it production-ready.

## Phase 1: no VM / safe local checks

- [ ] Unzip archive into WSL/Linux `~/projects`.
- [ ] Run `./scripts/verify-local.sh` (bash syntax, static guards).
- [ ] Install OpenTofu; run `cd opentofu && tofu init && tofu fmt -check && tofu validate`.
- [ ] Install Ansible collection; run syntax check with `ANSIBLE_CONFIG="$PWD/ansible/ansible.cfg" ansible-playbook --syntax-check -i ansible/inventory/hosts.ini.example ansible/site.yml` from repo root.
- [ ] Examine `git status` and `git ls-files`: no real credentials/state/keys.
- [ ] Confirm Compose only publishes `127.0.0.1:18789`, and no cloudflared service exists.

## Phase 2: Proxmox and SSH

- [ ] Template `9000` is valid, with QEMU guest agent.
- [ ] VM ID is unused, network and datastore correct.
- [ ] Unique Ed25519 key created and public key injected.
- [ ] Proxmox token has least privileges; secret stays out of repository.
- [ ] `tofu plan` creates expected VM only; `tofu apply` succeeds.
- [ ] First SSH host key verified; `ansible -m ping` succeeds.

## Phase 3: OpenClaw Gateway

- [ ] Ansible completes on Ubuntu 24.04 without modifying Cloudflare.
- [ ] `docker compose ps` reports running/healthy gateway.
- [ ] Host port is `127.0.0.1:18789`, not `0.0.0.0`.
- [ ] SSH port forward displays UI; Gateway token/pairing controls work.
- [ ] ChatGPT device-code OAuth works **and** a real model completion succeeds.
- [ ] Re-run Ansible and verify OAuth/state/cron preserved (idempotency).
- [ ] Create a simple scheduled report; inspect scheduler history.

## Phase 4: Manual Cloudflare only

- [ ] Create and install tunnel manually; **never** place token in IaC.
- [ ] Add `openclaw.example.com` published application to origin `http://127.0.0.1:18789` on same VM.
- [ ] Protect hostname with Cloudflare Access allowlist; unauthorized user is denied.
- [ ] Authorized browser reaches OpenClaw and still requires Gateway token/device trust.
- [ ] No router forward or public 18789 binding.

## Phase 5: Operations & release

- [ ] Back up and restore tested in non-production VM, including OAuth persistence.
- [ ] Pin a tested OpenClaw image tag for reproducible future deployments.
- [ ] Check application logs for secrets before sharing them.
- [ ] No broad GitHub write credential configured before secure task restrictions.
- [ ] Create empty GitHub repository and push only reviewed project files.
