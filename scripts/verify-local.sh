#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for x in bash python3; do command -v "$x" >/dev/null || { echo "Missing: $x"; exit 1; }; done
find scripts -maxdepth 1 -type f -name '*.sh' -print0 | xargs -0 -r -n1 bash -n
python3 - <<'PY'
from pathlib import Path
p=Path('opentofu/terraform.tfvars.example').read_text()
assert 'REPLACE_WITH_CONTENTS' in p
assert '192.0.2.' in p
compose=Path('ansible/templates/compose.yml.j2').read_text()
assert '127.0.0.1:' in compose
assert 'cloudflared:' not in compose
assert 'TUNNEL_TOKEN' not in compose
assert 'OPENCLAW_GATEWAY_TOKEN' in compose
print('Static guard checks passed.')
PY
python3 scripts/public-audit.py
if command -v tofu >/dev/null; then (cd opentofu && tofu fmt -check -recursive); else echo 'SKIP: tofu not installed; run tofu fmt and validate in WSL/Linux.'; fi
if command -v ansible-playbook >/dev/null; then ANSIBLE_CONFIG="$PWD/ansible/ansible.cfg" ansible-playbook --syntax-check -i ansible/inventory/hosts.ini.example ansible/site.yml; else echo 'SKIP: ansible-playbook not installed; syntax check after installing Ansible.'; fi
if command -v yamllint >/dev/null; then yamllint ansible/site.yml ansible/group_vars/all.yml ansible/requirements.yml; else echo 'Optional: install yamllint for additional checks.'; fi
