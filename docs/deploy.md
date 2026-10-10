# Step-by-step deployment: OpenTofu -> Ansible -> OpenClaw

This guide assumes you completed [Windows + WSL](windows-wsl.md) **or** [Linux](linux.md), generated a new [SSH key](ssh.md), and prepared [Proxmox](proxmox.md). All commands are run **inside WSL Ubuntu or native Linux** unless labeled `ON THE VM`. Never run Ansible directly from native Windows PowerShell.

## 1. Enter the extracted repository

```bash
cd ~/projects/openclaw-proxmox
pwd
ls README.md opentofu/main.tf ansible/site.yml
```

## 2. Validate SSH key

```bash
ls -l ~/.ssh/openclaw_01_ed25519*
ssh-keygen -lf ~/.ssh/openclaw_01_ed25519.pub
realpath ~/.ssh/openclaw_01_ed25519
cat ~/.ssh/openclaw_01_ed25519.pub
```

If missing, stop and follow [ssh.md](ssh.md). Record the private-key **absolute Linux path** and the public key text. You will use both in the next step.

## 3. Configure OpenTofu (controller)

```bash
cp opentofu/terraform.tfvars.example opentofu/terraform.tfvars
nano opentofu/terraform.tfvars
```

Replace every placeholder: Proxmox endpoint, node, VM ID, template ID, bridge, datastore, guest IP/gateway, **public** SSH key, and absolute path to **private** SSH key. If using DHCP, set IP and gateway fields to `null`. Proxmox API credentials do **not** belong in this file.

A basic local lint (requires no deployed VM):

```bash
./scripts/verify-local.sh
```

## 4. Supply Proxmox API token securely

Do not put the token in Bash history or shell command arguments. Use a hidden input prompt in WSL/Linux:

```bash
read -r -s -p 'Proxmox API token: ' PROXMOX_VE_API_TOKEN; echo
export PROXMOX_VE_API_TOKEN
```

Paste the token `user@realm!tokenid=secret` and press Enter. OpenTofu's Proxmox provider reads this environment variable. The token is **not** written into OpenTofu state by our configuration. Proxmox VM/cloud-init metadata can still appear in local state, which must remain private.

## 5. Plan and create VM

```bash
cd opentofu
tofu init
tofu fmt -check
tofu validate
tofu plan -out=openclaw.tfplan
```

Read the entire plan. Ensure it creates one **new** VM and a local inventory, and does not replace existing production VMs. If correct:

```bash
tofu apply openclaw.tfplan
tofu output
cd ..
unset PROXMOX_VE_API_TOKEN
```

Your ignored Ansible inventory should now exist:

```bash
cat ansible/inventory/hosts.ini
```

Do not commit it: it contains private network and local key-path information. If the clone fails, diagnose storage role/permissions and cloud-init template properties before rerunning. Do not blindly use `tofu destroy` to recover from partial issues.

## 6. Confirm first SSH connection

Replace the documentation IP with the real address from your guest network or `tofu output`:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/openclaw_01_ed25519
ssh -o IdentitiesOnly=yes -i ~/.ssh/openclaw_01_ed25519 ubuntu@192.0.2.55
```

On first login, compare the SSH host fingerprint against the Proxmox console as described in [ssh.md](ssh.md). Once logged in, confirm internet access:

```bash
cat /etc/os-release
ip -brief address
getent hosts ghcr.io
curl -I https://docs.openclaw.ai
exit
```

## 7. Deploy Docker and OpenClaw using Ansible

On your **controller**, back in the project root, **first set your real HTTPS hostname in ignored `ansible/group_vars/local.yml`** (copy `local.yml.example` if you have not already). That setting controls the Gateway public origin on its first initialization. Do not commit `local.yml`.

```bash
cp ansible/group_vars/local.yml.example ansible/group_vars/local.yml
nano ansible/group_vars/local.yml
cd ansible
ansible-galaxy collection install -r requirements.yml
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible -i inventory/hosts.ini openclaw -m ping
ansible-playbook -i inventory/hosts.ini site.yml
cd ..
```

Expected ping result contains `SUCCESS` with `"ping": "pong"`. The playbook installs Docker packages, creates persistent directories, generates Gateway token once, establishes baseline config once, starts the official OpenClaw Docker image, and publishes only `127.0.0.1:18789` on the VM. **It does not connect ChatGPT or install/configure Cloudflare Tunnel.**

The first image pull can take time; if deployment fails, inspect Ansible output and [troubleshooting.md](troubleshooting.md). `docker compose` operations are performed as the Ubuntu account in the Docker group. That group effectively grants root-level host control: use a dedicated VM and restrict account access.

## 8. Confirm container on VM

```bash
ssh -i ~/.ssh/openclaw_01_ed25519 ubuntu@192.0.2.55
cd /opt/openclaw
docker compose ps
docker compose logs --tail 80 openclaw-gateway
docker compose port openclaw-gateway 18789
```

Expected publish address starts with `127.0.0.1:18789`. If you see `0.0.0.0`, stop and correct Compose.

Check local browser access with an SSH local tunnel, on your **controller** in a *second terminal*:

```bash
ssh -N -L 18789:127.0.0.1:18789 -i ~/.ssh/openclaw_01_ed25519 ubuntu@192.0.2.55
```

Then visit `http://127.0.0.1:18789` on your controller's browser. A Gateway token is stored at `/opt/openclaw/.env`; see [operations.md](operations.md) for safe local retrieval. Browser device pairing may be required after login.

## 9. Configure OpenAI/ChatGPT OAuth

**ON THE VM**, from `/opt/openclaw`:

```bash
# Explicit device-code sign-in for a headless server:
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js models auth login --provider openai --device-code
```

Follow the one-time browser device authorization using your ChatGPT account. **Do not paste a token or one-time code into Git.** Afterward:

```bash
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js models list --provider openai
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js models status
```

Select a supported model by exact name from the list. For example the documented OpenClaw initial model is `openai/gpt-6-astra`, **if your account actually offers it**:

```bash
docker compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js config set agents.defaults.model.primary openai/gpt-6-astra
docker compose up -d openclaw-gateway
```

Send a real message through the UI. Merely logging in or seeing a model in a catalog is **not** proof the model is authorized for inference. [ChatGPT Plus and model debugging](chatgpt-plus.md) explains access failures.

## 10. Create Cloudflare routing MANUALLY

Follow [cloudflare-manual.md](cloudflare-manual.md). Cloudflare Tunnel must be created, installed and managed by **you**, separately from IaC. Configure `openclaw.example.com` -> `http://127.0.0.1:18789` only if the manually installed `cloudflared` connector runs on this exact VM. Require a Cloudflare Access identity policy before using the hostname broadly.

## 11. Reboot/redeploy checks

```bash
# ON THE VM:
sudo reboot
# After reconnect:
cd /opt/openclaw
docker compose ps
docker compose logs --tail 40 openclaw-gateway
```

Re-run Ansible after reviewing changed code. Existing OpenClaw state/OAuth must survive. Before meaningful upgrades, follow [operations.md](operations.md) to back up the VM state and pin a release image.

## 12. Review before first public Git push

```bash
cd ~/projects/openclaw-proxmox
git status --short
./scripts/verify-local.sh
git diff --check
git ls-files | grep -E '(terraform\.tfvars$|tfstate|hosts\.ini$|\.env$|\.pem$|\.key$)' && echo 'REVIEW: possible secret!' || echo 'No obvious tracked sensitive paths.'
```

See [security.md](security.md) before publishing.
