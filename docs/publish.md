# Publish this project as a NEW GitHub repository (after local validation)

These commands deliberately **do not** create or modify your GitHub account automatically. The ZIP is a local starter; you decide when to publish. Before publishing, read [security.md](security.md) and run the checks in [validation.md](validation.md).

## 1. Extract and inspect

Use WSL2 Ubuntu or Linux:

```bash
mkdir -p ~/projects
cd ~/projects
unzip ~/Downloads/openclaw-proxmox-public.zip # Windows: copy from /mnt/c/Users/.../Downloads first
cd openclaw-proxmox
./scripts/verify-local.sh
```

## 2. Create a Git repository locally

```bash
git init
# Set these if git complains that identity is missing:
git config --global user.name 'YOUR NAME'
git config --global user.email 'you@example.com'
git add README.md CONTRIBUTING.md LICENSE .gitignore .editorconfig Makefile \
  .github opentofu ansible scripts docs
git status --short
python3 scripts/public-audit.py
```

Confirm `terraform.tfvars`, Ansible's live `hosts.ini`, `.env`, keys, OAuth files, and `tfstate` are **not** staged. Run `python3 scripts/public-audit.py` and inspect its results. Run `git diff --cached --check` and `git diff --cached --name-only` before committing. If they are, remove them from the staging area and fix `.gitignore` before proceeding. Do not use `git add -f` on ignored credentials.

```bash
git commit -m 'feat: add OpenClaw Proxmox Docker deployment'
git branch -M main
```

## 3. Create a new GitHub repository

In the GitHub browser, create `openclaw-proxmox` under your own GitHub account. Leave the initial README/license/gitignore options empty; this project already contains those. Pick Public **only after** reviewing secrets, private addressing, and identifiers. If this project was ever committed with a real secret, removing the file from the latest commit is insufficient: rotate it and rewrite exposed history.

## 4. Push to GitHub

From WSL/Linux:

```bash
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/openclaw-proxmox.git  # replace YOUR_GITHUB_USERNAME
git push -u origin main
```

GitHub may require interactive browser/PAT/GitHub CLI auth. If you already use SSH for GitHub, use `git@github.com:YOUR_GITHUB_USERNAME/openclaw-proxmox.git` after separately configuring a **GitHub account SSH key**. That GitHub key does not need to be the same as the dedicated OpenClaw VM SSH key; keeping them separate is preferable.

## 5. Subsequent changes

```bash
git switch -c docs/update-install-notes
# make your edits
git add docs/
git commit -m 'docs: improve installation guide'
git push -u origin docs/update-install-notes
```

Open a PR to `main`, run CI and review it before merging. Keep real infrastructure files ignored even if you modify documentation.
