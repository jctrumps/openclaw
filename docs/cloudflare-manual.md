# Manually configure Cloudflare DNS, Tunnel and Access — NO tunnel secrets in IaC

**This is operator documentation only.** `openclaw.example.com` and `example.com` are reserved documentation placeholders; replace them with a hostname and zone you own. Never publish an example.com hostname as a real target. OpenTofu and Ansible do not create, configure, update, or run Cloudflare Tunnel. The repo has **no Tunnel token variables**. The tunnel service is installed **manually by you** *after* OpenClaw is running. It must run on the **same Ubuntu VM** as the private Docker port for the origin below to work.

## Before using the public hostname

1. Confirm `docker compose port openclaw-gateway 18789` on the VM displays `127.0.0.1:18789`.
2. Confirm browser login works via an SSH local port forward.
3. Before deploying, set `openclaw_public_origin` to your actual HTTPS hostname in the **ignored** `ansible/group_vars/local.yml` (created from `.example`), then confirm Gateway token and ChatGPT model access. The tracked `example.com` origin is only a placeholder.
4. Consider who should be able to run OpenClaw, which can invoke agent tools and reach configured repositories/services.

## 1. Create a tunnel manually in Cloudflare

In the [Cloudflare dashboard](https://dash.cloudflare.com/), navigate **Networking → Tunnels** (menus may shift). Create a **remotely managed** tunnel, e.g. `openclaw-01`, and select the **Linux** installation method. Cloudflare will display a connector install command containing a **secret tunnel token**.

**Run the Cloudflare-provided connector install command manually in an SSH session on the Ubuntu VM**, not through this Git repository, OpenTofu, Ansible, GitHub Actions, or chat. Treat the command and resulting service credentials as secrets. Avoid saving the token command in Bash history, shared terminal recordings, or docs. Cloudflare commonly uses `sudo cloudflared service install <TUNNEL_TOKEN>` for Linux: copy the real command only from your own Cloudflare dashboard. This project does not know or need that token.

The command typically installs a `cloudflared` systemd service on the guest. You manage it and its credentials outside this repo:

```bash
# On the VM, after installing the connector manually:
sudo systemctl status cloudflared --no-pager
# If troubleshooting, avoid publishing auth-token-bearing logs:
sudo journalctl -u cloudflared -n 50 --no-pager
```

If your connector already runs on **another VM**, `127.0.0.1` on that other VM is **not** OpenClaw. Either install a new tunnel connector on the OpenClaw VM or use a separately reviewed private-network origin route; do not weaken the OpenClaw Docker binding as a shortcut.

## 2. Create the restrictive Cloudflare Access application FIRST

Before publishing a route, create the self-hosted Cloudflare Access application for `openclaw.example.com` with a deny-by-default posture and a restrictive **Allow** identity policy. Verify your identity provider and MFA where available. This avoids a period of unintended public reachability while the route is being enabled. The detailed Access checks appear in the next section.

## 3. Add the published hostname in the Cloudflare dashboard

In the tunnel's **Routes → Add route → Published application**, set:

| Field | Value |
| --- | --- |
| Hostname subdomain | `openclaw` |
| Domain | `example.com` |
| Service type | HTTP |
| Service URL | `http://127.0.0.1:18789` |

Save. Cloudflare manages the DNS route/CNAME for its tunnel when added through the dashboard. **Do not add an A record to your Proxmox public IP, and do not forward port 18789.** DNS becoming active is not authentication.

## 4. Verify Cloudflare Access protects every request

In **Cloudflare Zero Trust / Access → Applications**, verify the self-hosted application for `openclaw.example.com` created in step 2 has an **Allow** policy for your verified identity (for example, your own email identity with an OTP or your identity provider), and a deny-by-default posture. Do not allow "Everyone" just to test the route.

Use a short session duration, MFA via your IdP where available, and review Cloudflare's cookie/WebSocket behavior if the OpenClaw Control UI refuses to connect. Cloudflare Access protects ingress before OpenClaw's own Gateway token and device authorization. **Keep both layers**.

## 5. Validate origin configuration

On first deployment, Ansible sets `gateway.publicOrigin` to `openclaw_public_origin` from your configuration. **Set that local override to your real hostname before running Ansible**; the committed `example.com` value is only a template. Newer versions use that origin as the default browser-origin allowlist. Confirm:

```bash
# ON THE VM:
cd /opt/openclaw
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js config get gateway.publicOrigin
```

If your hostname changes later, explicitly update that setting:

```bash
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js config set gateway.publicOrigin https://YOUR-NEW-HOSTNAME
# Restart only after checking settings:
docker compose up -d openclaw-gateway
```

The browser may also require approved device pairing and a Gateway token. Don't bypass pairing or disable origin checks to "make the tunnel work."

## 6. Test three separate paths

**A. VM loopback:** on VM `curl -I http://127.0.0.1:18789` (even 401/403 can indicate app responding). **B. SSH-only:** tunnel `ssh -N -L 18789:127.0.0.1:18789 ...` and browse localhost from your workstation. **C. Public HTTPS:** browse `https://openclaw.example.com` from a different network; verify Cloudflare Access blocks unauthorized identity and allows only your account; then OpenClaw still requires its own authentication.

A `502` usually indicates Cloudflare can't reach its configured local origin, the tunnel connector is on a different VM, or the container is stopped. Cloudflare docs: <https://developers.cloudflare.com/tunnel/get-started/>.

## Security boundaries

- No Cloudflare API token or tunnel token in this repository or the OpenClaw Docker `.env`.
- No Ansible task that installs or configures cloudflared.
- No `cloudflared` service in Docker Compose.
- No public inbound Proxmox port forwarding needed.
- Treat `cloudflared` installation files and VM backups as credentials.
