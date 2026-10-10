# Troubleshooting by failure stage

## WSL / Linux controller

**`tofu: command not found`:** install OpenTofu **inside WSL**, not only Windows, then `tofu version`. **`ansible: command not found`:** `pipx ensurepath`, reopen shell, and verify `~/.local/bin` is in `PATH`. **World-writable `/mnt/c` warning or ignored `ansible.cfg`:** work from `~/projects` (Linux filesystem) and export `ANSIBLE_CONFIG="$PWD/ansible.cfg"` inside `ansible/`.

**SSH `Permission denied (publickey)`:** `ssh-add -l`; compare local public key with cloud-init; check `ansible_user=ubuntu` and private key path is a Linux path. **SSH `Host key verification failed`:** verify the host's actual public key fingerprint from Proxmox console; never globally disable StrictHostKeyChecking.

## OpenTofu / Proxmox

**401 invalid token:** `PROXMOX_VE_API_TOKEN` missing/incorrect, or wrong endpoint/realm. **403 allocation:** review API role and grants to datastore, node, and VM pool; `Datastore.AllocateSpace` is frequently necessary. **Clone error:** verify template VMID exists on the targeted node, disk interface, datastore compatibility, and `QEMU Guest Agent`. **Inventory name won't resolve:** DHCP inventory uses VM name; change ignored generated `ansible/inventory/hosts.ini` to IP or use a static address.

If a provider version update fails planning, check `opentofu/versions.tf` and upstream `bpg/proxmox` release notes. Run `tofu plan` and inspect carefully rather than forcing `-upgrade` in production.

## Docker / Ansible

**Docker apt signature error:** examine `/etc/apt/keyrings/docker.asc`, apt repo architecture and Ubuntu codename. **`Cannot connect to Docker daemon`:** `sudo systemctl status docker`; log out/in after initial group membership, or run Docker via sudo on the VM. **Healthcheck reports unhealthy:** `cd /opt/openclaw && docker compose logs --tail=150 openclaw-gateway`.

**Port isn't reachable:** `docker compose port openclaw-gateway 18789`; expected host `127.0.0.1`. Access from your workstation requires the SSH `-L` forward. The gateway intentionally listens on `lan` **inside Docker only**, since container-loopback would not accept traffic over Docker's bridge.

**Gateway config absent or first bootstrap failed:** verify `ls -la /srv/openclaw/state/`, permissions, and the official image tag. Then inspect `setup --baseline` syntax via `docker compose run --rm --no-deps --entrypoint node openclaw-gateway dist/index.js setup --help`. Don't delete a working configuration to force a rerun.

## ChatGPT model auth

**Device login fails:** ensure outbound browser/OAuth endpoints are accessible and the clock is correct. Repeat interactive device-code login. **Authenticated but model rejected:** this may be an account/model-route restriction; it does not prove the Gateway is broken. Check `models list --provider openai`, `models status`, select an actual authorized model, and test a completion. **OpenCode works, OpenClaw doesn't:** implementations and model permissions/routes can differ; compare precise model ID and OpenClaw runtime logs. Avoid endless retries.

## Cloudflare route

**Cloudflare 502:** the connector runs on a different machine, Gateway stopped, `service URL` wrong, or local port unavailable. On the VM run `curl -I http://127.0.0.1:18789` and `sudo systemctl status cloudflared`. **Cloudflare 403/Access screen:** review manually created Access application policy. **Browser WebSocket/origin error:** confirm `gateway.publicOrigin` matches `https://openclaw.example.com` and use documented allowed-origin settings instead of unsafe Host-header fallbacks. **Tunnel token unavailable:** this repo intentionally does not manage it; check your Cloudflare Zero Trust dashboard and connector install procedure.

## Restore or persistence

If changes disappear after image upgrade, check container mounts in `compose.yml` and ensure you didn't delete `/srv/openclaw`. If credentials were accidentally committed, revoke them and rewrite Git history appropriately; `.gitignore` alone cannot unpublish a committed secret.
