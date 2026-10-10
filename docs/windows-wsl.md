# Windows 10/11 -> WSL2 -> OpenTofu and Ansible

**Run OpenTofu and Ansible inside Ubuntu on WSL**, not from PowerShell. Use PowerShell only to install and enter WSL. A native Windows OpenTofu install is possible, but it creates path/key mismatches with Ansible and this guide intentionally uses one Linux environment for both.

## 1. Install WSL2

Open **PowerShell as Administrator**:

```powershell
wsl --install -d Ubuntu
```

Reboot if Windows requests it. Run Ubuntu from Start menu, create a Linux username/password (not necessarily your Windows username). Check in PowerShell:

```powershell
wsl --status
wsl --list --verbose
```

If Ubuntu displays version 1, upgrade in PowerShell: `wsl --set-version Ubuntu 2`. Launch Ubuntu using `wsl -d Ubuntu`.

## 2. Install Linux tools INSIDE Ubuntu

```bash
sudo apt update
sudo apt install -y git curl wget gpg ca-certificates unzip openssh-client python3 python3-pip python3-venv pipx make
pipx ensurepath
exec bash -l
pipx install --include-deps ansible
ansible --version
```

If `ansible` is not found, close and reopen Ubuntu or run `source ~/.profile`; ensure `~/.local/bin` is in your `PATH`.

## 3. Install OpenTofu INSIDE Ubuntu

Official installer instructions may change; review <https://opentofu.org/docs/intro/install/> before use. For Ubuntu x86_64, OpenTofu publishes an installation script:

```bash
# Inspect the installer URL before execution and review official instructions.
curl -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh
less /tmp/install-opentofu.sh
chmod +x /tmp/install-opentofu.sh
/tmp/install-opentofu.sh --install-method deb
rm -f /tmp/install-opentofu.sh
tofu version
```

If this install method no longer exists, use the official package-manager instructions instead. Verify `tofu version` before provisioning.

## 4. Put the project under the Linux filesystem

Use `~/projects` rather than `/mnt/c/Users/...` because Windows NTFS mounts have different Unix permissions, particularly for SSH private keys, and Ansible may ignore `ansible.cfg` under world-writable mounts.

```bash
mkdir -p ~/projects
cd ~/projects
# After downloading the ZIP into Windows Downloads:
cp /mnt/c/Users/YOUR_WINDOWS_USERNAME/Downloads/openclaw-proxmox-public.zip .
unzip openclaw-proxmox-public.zip
cd openclaw-proxmox
pwd
```

Or clone a repository after pushing it to GitHub:

```bash
# Only after you publish the repository under your own GitHub account:
git clone https://github.com/YOUR_GITHUB_USERNAME/openclaw-proxmox.git
cd openclaw-proxmox
```

The example clone assumes you create that repository; it does not exist as part of this ZIP generation.

## 5. Unique SSH keys and permissions

Continue with [ssh.md](ssh.md). **Generate SSH keys inside WSL** so Unix file permissions remain intact. The path in OpenTofu must be an absolute Linux path such as `/home/YOUR_LINUX_USERNAME/.ssh/openclaw_01_ed25519`, not `C:\Users\...`.

## 6. Cross-boundary commands

```powershell
# Run from PowerShell to enter WSL:
wsl -d Ubuntu
# Optional: open current WSL folder in Windows Explorer (run inside WSL):
```

```bash
explorer.exe .
# Open project in VS Code if the `code` WSL integration is installed:
code .
# Validate runtime location and key permissions:
pwd
ls -l ~/.ssh/openclaw_01_ed25519
```

**Important:** `terraform.tfvars` must contain the private-key path from `realpath ~/.ssh/openclaw_01_ed25519`. OpenTofu only writes that path to the ignored local Ansible inventory; private key material is never sent to Proxmox (only public key is).

## 7. Finish the deployment

Follow [deploy.md](deploy.md) starting at "Configure OpenTofu". Use the exact same Ubuntu WSL terminal for `tofu` and `ansible-playbook`.
