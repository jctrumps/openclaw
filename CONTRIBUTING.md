# Contributing

This repository provides reproducible, reviewable infrastructure for one self-hosted OpenClaw instance. Keep the design small and operator-friendly.

## Workflow

1. Fork or create a feature branch: `git switch -c feature/short-description`.
2. Read [docs/architecture.md](docs/architecture.md) and [docs/security.md](docs/security.md).
3. Change the smallest relevant layer: OpenTofu for guest resources, Ansible for guest/app, docs for manual Cloudflare steps.
4. Run `./scripts/verify-local.sh`, `tofu fmt`, `tofu validate`, and `ansible-playbook --syntax-check` if tools are available.
5. Document manual verification and affected settings in your PR.
6. Never paste full `docker compose config` output into public issue reports; expanded values can reveal Gateway tokens.

## Non-negotiable rules

- **Cloudflare credentials must remain outside the repository and its automation.** Keep Cloudflare as a manual operator step unless project scope explicitly changes.
- No API tokens, SSH private keys, OAuth exports, auth-profile files, live host inventories, state, or database backups in Git.
- Do not expose `18789` on `0.0.0.0` or through a firewall port forward.
- No unreviewed automatic container upgrades; credential and config migration can break working models.
- Preserve idempotency: Ansible reruns must not replace app tokens or OAuth profiles.
- Keep the documentation complete enough for a fresh Windows/WSL or Linux workstation.
- Pin and review external GitHub Actions and third-party automation before relying on production deployments.

## Commit style

Conventional prefixes are welcome: `docs:`, `fix:`, `feat:`, `chore:`. Include why a network, security or identity behavior changed.

## Security issues

Do not post an exploitable issue or credential in public. First revoke any exposed secrets, then report privately using the appropriate GitHub security-contact mechanism.
