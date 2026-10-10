# Native Linux controller setup (Ubuntu/Debian)

Run every command in a terminal on your Linux workstation. This guide assumes Ubuntu 24.04 or similar; adjust package names for other distributions.

```bash
sudo apt update
sudo apt install -y git curl wget gpg ca-certificates unzip openssh-client python3 python3-pip python3-venv pipx make
pipx ensurepath
exec bash -l
pipx install --include-deps ansible
ansible --version
```

OpenTofu installation: review <https://opentofu.org/docs/intro/install/>. One published installer path is:

```bash
curl -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh
less /tmp/install-opentofu.sh
chmod +x /tmp/install-opentofu.sh
/tmp/install-opentofu.sh --install-method deb
rm -f /tmp/install-opentofu.sh
tofu version
```

Unzip:

```bash
mkdir -p ~/projects
cd ~/projects
unzip ~/Downloads/openclaw-proxmox.zip
cd openclaw-proxmox
```

Next read [ssh.md](ssh.md), [proxmox.md](proxmox.md), and then [deploy.md](deploy.md). SSH key generation is the same on native Linux and WSL. Avoid running OpenTofu under `sudo`; only installation packages and guest OS configuration use root privileges.
