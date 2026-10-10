# SSH: create a UNIQUE key just for the OpenClaw VM

Do this in WSL Ubuntu or native Linux on the controller. The **private key never goes in Git**. Never reuse the key from Paperclip, Hermes, or any existing Proxmox VM.

## 1. Generate a dedicated Ed25519 identity

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/openclaw_01_ed25519 -C "openclaw-01-$(whoami)"
chmod 600 ~/.ssh/openclaw_01_ed25519
chmod 644 ~/.ssh/openclaw_01_ed25519.pub
```

When prompted, **choose a unique passphrase** and store it in your password manager. `-f` names the private key; `.pub` is the corresponding public key.

## 2. Inspect the public key and private-key path

```bash
cat ~/.ssh/openclaw_01_ed25519.pub
realpath ~/.ssh/openclaw_01_ed25519
```

Paste the **entire single-line public key** into `ssh_public_key` in `opentofu/terraform.tfvars`. Paste the absolute path from `realpath` into `ssh_private_key_file`. Do NOT paste private-key content.

## 3. Unlock the passphrase for a session

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/openclaw_01_ed25519
ssh-add -l
```

The generated Ansible inventory additionally specifies the key filename, but `ssh-agent` provides its passphrase in memory so automation does not repeatedly ask for it.

## 4. First guest login and host-key trust

Once OpenTofu creates the VM, get its actual address. Use `-o IdentitiesOnly=yes` to prevent SSH from offering unrelated identities:

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/openclaw_01_ed25519 ubuntu@192.0.2.55
```

**Example address only**: replace `192.0.2.55`. On the first connection, SSH asks whether to trust the server's *host key*. Compare its fingerprint with the Proxmox VM console (`sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`) before typing `yes`. Do not disable host-key checking globally.

## 5. Optional SSH config shortcut

Inside WSL/Linux, create/edit `~/.ssh/config`:

```sshconfig
Host openclaw-vm
  HostName 192.0.2.55
  User ubuntu
  IdentityFile ~/.ssh/openclaw_01_ed25519
  IdentitiesOnly yes
  ServerAliveInterval 30
```

Then `chmod 600 ~/.ssh/config` and `ssh openclaw-vm`.

## 6. Common mistakes

- `Permission denied (publickey)`: verify **matching** `.pub` was injected into cloud-init; run `ssh-add -l`; check VM username is `ubuntu`.
- `UNPROTECTED PRIVATE KEY FILE!`: key resides under `/mnt/c`, or permissions are too open; move to `~/.ssh` inside WSL and `chmod 600`.
- VM was previously deployed with another public key: cloud-init may not reapply user keys; reprovision with care or add authorized key via console.
- `REMOTE HOST IDENTIFICATION HAS CHANGED`: investigate the host key in Proxmox console before removing a known_hosts entry. Do not blindly bypass it.
