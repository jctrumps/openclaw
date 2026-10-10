# GitHub integration: one VM, multiple repositories

OpenClaw is not granted access to GitHub by default. The official container focuses on the Gateway; it may not include the GitHub CLI (`gh`) or development build toolchain. Do **not** assume `gh` is present. This project provisions persistent `/home/node/repos`, `/home/node/.config/gh`, and `/home/node/.ssh` mounts for **later, intentional** GitHub access.

## Option A — safest starting point

Start with a **single test repository**. Use HTTPS public clones for read-only experiments and create a separate limited credential when write access is justified. Examples of public read-only check (on VM):

```bash
cd /opt/openclaw
# Confirm git and gh availability inside current image:
docker compose exec openclaw-gateway sh -lc 'command -v git || true; command -v gh || true'
```

If `git` exists:

```bash
docker compose exec -u node openclaw-gateway sh -lc 'cd /home/node/repos && git clone https://github.com/cli/cli.git'
```

If Git isn't installed, extend the official image with a reviewed custom Dockerfile containing git, gh and ssh, then update `openclaw_image` to the resulting local image. Do not install tools ad hoc inside a running container and assume they survive upgrades. See [operations.md](operations.md).

## Option B — one GitHub credential across several repositories

For a multi-repository setup, use **GitHub CLI authenticated to an account or GitHub App credential with only the repositories and rights you need**. Prefer an appropriately scoped GitHub App installation token for unattended write automation; app tokens expire and should be refreshed through an approved secret-management mechanism. For interactive testing, a fine-grained PAT with selected repositories and minimum scopes can be stored by `gh auth login`, but it remains sensitive and should not be copied into prompts or Git.

After you have built or selected an image containing `gh` and `git`, you can authenticate interactively:

```bash
# On VM; be conscious this command runs gh inside an agent-capable container.
cd /opt/openclaw
docker compose exec -it -u node openclaw-gateway gh auth login
# Choose GitHub.com, HTTPS, and browser login when offered.
docker compose exec -it -u node openclaw-gateway gh auth status
```

OpenClaw's mount `/srv/openclaw/gh-config:/home/node/.config/gh` persists gh's local authentication profile between image upgrades. Some `gh` flows use host-specific credential helpers; if token storage fails, configure a supported credential helper **within the container's persisted directories**. Treat VM data and its backup as containing GitHub secrets.

Clone approved repositories into the persistent workspace:

```bash
docker compose exec -it -u node openclaw-gateway sh
cd /home/node/repos
gh repo clone YOUR_GITHUB_USERNAME/YOUR_TEST_REPOSITORY
# Add other approved repos individually. Then exit.
exit
```

## GitHub security rules for agents

- Use a dedicated low-privilege GitHub account or GitHub App where feasible, never an owner's classic unrestricted token.
- Start with a branch + pull request workflow. Do not permit direct commits to protected main branches.
- Never allow an agent to install itself as a repository administrator.
- Set repository allowlists and review dangerous shell actions or `git push --force`.
- Treat GitHub issue text, PR comments and repository files as untrusted input that can contain prompt-injection instructions.
- If the host OpenClaw account uses the Docker group or the container has broad host mounts, treat that access as high privilege.

## Optional image extension example

If `git` or `gh` is missing, **review** this example and create a local Dockerfile under a separate untracked workspace or version it with explicit approval:

```dockerfile
ARG BASE_IMAGE=ghcr.io/openclaw/openclaw:latest
FROM ${BASE_IMAGE}
USER root
RUN apt-get update && apt-get install -y --no-install-recommends git gh openssh-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*
USER node
```

This assumes a Debian-derived official base with `apt-get`. Verify upstream's actual base for your pinned tag. You would build it on the VM (`docker build --build-arg BASE_IMAGE=... -t openclaw-git:local .`) and set `openclaw_image: openclaw-git:local` in ignored `ansible/group_vars/local.yml`, or edit Compose only for a documented custom deployment. The standard playbook pulls official images and does not build custom images by default.
