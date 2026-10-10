# Architecture

## Boundaries

The workstation hosts OpenTofu + Ansible, not OpenClaw. The VM hosts Docker; Docker hosts OpenClaw. A cloudflared service, installed **manually by you on that same Ubuntu guest**, dials out to Cloudflare and reaches the Docker-published **host-local** origin at `127.0.0.1:18789`. Cloudflare Access gates the browser before it reaches the tunnel. The OpenClaw Gateway separately validates its own auth token and browser-device pairing.

```text
Internet browser -> Cloudflare Access identity check -> DNS / published hostname
                   -> Cloudflare Tunnel -> MANUALLY INSTALLED cloudflared service
                   -> localhost:18789 (Ubuntu VM)
                   -> Docker bridge port mapping -> OpenClaw gateway:18789

VM: /opt/openclaw/.env          (private gateway token)
    /opt/openclaw/compose.yml   (generated declarative container config)
    /srv/openclaw/state         (settings, OAuth profiles, workspace, cron)
    /srv/openclaw/auth-profile-secrets (profile key material)
    /srv/openclaw/repos         (opt-in development worktrees)
    /srv/openclaw/gh-config     (optional GitHub CLI credentials)
    /srv/openclaw/ssh-config    (optional Git identity/SSH keys)
```

## Why `gateway --bind lan` when host port is private?

Inside Docker bridge mode, `127.0.0.1` refers to the *container itself*. To accept the forwarded host-published port, OpenClaw must listen on the container bridge interface. Compose publishes the host side as `127.0.0.1:18789:18789`. Therefore the guest's port is **not** reachable via the LAN or Internet even though the application binds within its Docker namespace. Cloudflare Tunnel runs on the guest host, where it can access host loopback.

## Persistent state

Docker volumes are bind mounts under `/srv/openclaw`. Updating or replacing the container must not delete them. `/opt/openclaw/.env` contains a gateway token and must remain 0600. `setup --baseline` and `gateway.publicOrigin` configuration run only when `/srv/openclaw/state/openclaw.json` is missing. This avoids clobbering existing auth or schedules on Ansible reruns.

## Failure domains

- Proxmox API failure: OpenTofu cannot provision; existing VM remains unaffected.
- SSH or guest failure: Ansible cannot connect; existing VM state remains on Proxmox storage.
- Docker failure: gateway goes down; inspect `docker compose logs`.
- ChatGPT auth failure: UI may work but AI model requests fail; inspect auth/model status.
- Cloudflare failure: external UI unavailable; SSH port forward continues working if SSH is available.

## Scope exclusions

No cloudflared container, tunnel token, Cloudflare DNS record, Access application, Proxmox port forwarding, or public IP endpoint is created by this project.
