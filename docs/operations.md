# Day-two operations: status, upgrades, backups, restores

All commands in this guide are **ON THE OPENCLAW VM** unless otherwise noted. Use the WSL/native Linux SSH identity from [ssh.md](ssh.md).

## Daily health and logs

```bash
cd /opt/openclaw
docker compose ps
docker compose logs --tail=100 openclaw-gateway
docker compose logs -f openclaw-gateway
curl -sSI http://127.0.0.1:18789/ || true
```

Do not paste raw logs publicly without redacting tokens/URLs/authorization headers. Check remote Access availability **separately** from local gateway status.

## Gateway token

The playbook generates a random 32-byte hex token *only once*. It is in `/opt/openclaw/.env` (0600). To copy for your own UI authentication, view it only in a private terminal session:

```bash
cd /opt/openclaw
chmod 600 .env
# Avoid forwarding this output into shared logs or bug reports:
cat .env
```

Do not store the token in a GitHub Actions secret unless you have a genuine CI requirement and have designed appropriate access restrictions. Cloudflare Tunnel token is a **different credential**, created and kept entirely outside this repo.

## Restart and upgrades

```bash
cd /opt/openclaw
docker compose restart openclaw-gateway
```

A restart does **not** apply a changed image tag or environment variable. For a deliberate update:

1. Create an encrypted backup and a Proxmox VM snapshot if available.
2. Review <https://github.com/openclaw/openclaw/releases> for migration changes.
3. Pin a tested tag (instead of `latest`) in ignored `ansible/group_vars/local.yml` using `openclaw_image: ghcr.io/openclaw/openclaw:RELEASE_TAG`.
4. Run Ansible again from WSL/Linux (`ansible-playbook -i inventory/hosts.ini site.yml`). Compose will recreate on changed image reference; if necessary manually pull and recreate as below.

```bash
# ON VM, after the image tag in compose.yml has been changed by Ansible:
cd /opt/openclaw
docker compose pull openclaw-gateway
docker compose up -d openclaw-gateway
docker compose logs --tail=80 openclaw-gateway
```

If using a moving `latest` tag, Ansible's `pull: missing` won't necessarily download a newer image. Explicit pulls are intentional upgrades. Always check OAuth/model access after upgrading.

## Backups (contain secrets)

The included `scripts/backup-guest.sh` must be **copied to the VM manually** if needed, or run from a checked-out working copy on the VM. This script stops the Gateway briefly, archives `/opt/openclaw` and `/srv/openclaw`, restarts the Gateway, and writes a mode-0600 tarball.

```bash
# On controller (from repository root):
scp -i ~/.ssh/openclaw_01_ed25519 scripts/backup-guest.sh ubuntu@192.0.2.55:/tmp/backup-openclaw.sh
# On the VM:
sudo bash /tmp/backup-openclaw.sh /root/openclaw-backups
sudo ls -lh /root/openclaw-backups
```

**Encrypt before offsite transfer.** A backup contains OAuth refresh credentials, Gateway credentials, repositories, SSH/GitHub profiles (if configured), and chat/workspace content. Never store unencrypted archives in GitHub or publicly shared drives.

For quick VM-wide recovery, also use your normal Proxmox backup tooling with encryption/access controls appropriate for credentials and data.

## Restore (destructive)

The included `scripts/restore-guest.sh` restores paths from a **trusted project-generated archive** and overwrites existing files. Take a fresh backup or Proxmox snapshot before restore. Example:

```bash
# Controller, after choosing a trusted archive already present on VM:
scp -i ~/.ssh/openclaw_01_ed25519 scripts/restore-guest.sh ubuntu@192.0.2.55:/tmp/restore-openclaw.sh
# On VM (archive path must be local):
sudo bash /tmp/restore-openclaw.sh /root/openclaw-backups/openclaw-YYYYMMDDTHHMMSSZ.tar.gz
```

The script validates archive member prefixes and prompts `RESTORE`, but restoring untrusted tarballs remains unsafe. This is an operator-admin tool, not an agent task. It assumes the default `ubuntu` deployment user; adapt it if you changed `openclaw_os_user`.

## Reprovision / destroy

OpenTofu state is local and ignored. Preserve it securely to prevent duplicate VM creation and unsafe destruction. `tofu destroy` removes the Proxmox VM; it is **not** an OpenClaw uninstall button. Destroy only after backup/approval and never while referencing the wrong state.

## Image/container security

The official base image doesn't necessarily contain `gh`, `git`, or every browser automation dependency. Review [GitHub](github.md) if you want development tooling. Keep the host Docker socket **unmounted** into the Gateway: providing it would grant near-host-root power to the agent. Also avoid host-wide mounts and credentials for unrelated Proxmox services.
