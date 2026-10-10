#!/usr/bin/env python3
"""Prepublication hygiene checks, safe to run without third-party dependencies.

This intentionally checks common leaks, not every possible secret or personal identifier.
Never rely on a passing scan as a substitute for inspecting staged changes.
"""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SENSITIVE_PATHS = [
    re.compile(p, re.I) for p in (
        r'(^|/)terraform\.tfvars$',
        r'(^|/)terraform\.tfstate(?:\.|$)',
        r'(^|/)hosts\.ini$',
        r'(^|/)local\.yml$',
        r'(^|/)\.env(?:\.|$)(?!example$)',
        r'(^|/)\.ssh/',
        r'(^|/)(?:id_rsa|id_ed25519)(?:\.|$)',
        r'(^|/).*\.(?:pem|p12|pfx|key)$',
        r'(^|/).*vault.*\.yml$',
        r'(^|/)(?:auth-profiles|credentials|openclaw)\.json$',
        r'(^|/)(?:secrets|host_vars)/',
        r'\.(?:tfplan|tar|tar\.gz|zip|sqlite|db)$',
    )
]
SECRET_MARKERS = [
    ('private key block', re.compile(r'-----BEGIN (?:OPENSSH |RSA |EC |DSA |ENCRYPTED )?PRIVATE KEY-----')),
    ('GitHub token', re.compile(r'gh[pousr]_[A-Za-z0-9_]{20,}')),
    ('GitHub fine-grained token', re.compile(r'github_pat_[A-Za-z0-9_]{20,}')),
    ('OpenAI API key', re.compile(r'sk-(?:proj-)?[A-Za-z0-9_-]{20,}')),
    ('Cloudflare connector token', re.compile(r'(?i)(?:TUNNEL_TOKEN|CF_TUNNEL_TOKEN)\s*[:=]\s*["\x27]?[A-Za-z0-9._-]{35,}')),
    ('Proxmox API token value', re.compile(r'[A-Za-z0-9._-]+@(?:pam|pve)!\S+=[A-Za-z0-9_-]{15,}')),
    ('real network address', re.compile(r'(?<![\d.])(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})(?!\d)')),
    ('email address', re.compile(r'(?<![\w.-])[A-Za-z0-9._%+\-]+@(?!(?:example\.com|example\.org|example\.net)\b)[A-Za-z0-9.\-]+\.[A-Za-z]{2,}')),
]
# Ignore patterns above when declaring them in the scanner itself; otherwise it self-matches.
SKIP_CONTENT = {'scripts/public-audit.py'}

def tracked():
    # In a Git repo, inspect staged/tracked plus untracked, non-ignored files.
    # This works before the first commit and catches newly created files that
    # someone could accidentally include via `git add .`.
    if (ROOT / '.git').exists():
        r = subprocess.run(
            ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'],
            cwd=ROOT, capture_output=True, check=False,
        )
        if r.returncode != 0:
            raise RuntimeError('git ls-files failed: ' + r.stderr.decode(errors='replace'))
        return sorted(set(Path(s.decode()) for s in r.stdout.split(b'\0') if s))
    return [p.relative_to(ROOT) for p in ROOT.rglob('*') if p.is_file() and '.git' not in p.parts]

errors = []
files = tracked()
for relative in files:
    label = relative.as_posix()
    if any(r.search(label) for r in SENSITIVE_PATHS):
        errors.append(f'{label}: sensitive file path must not be published')
    if label in SKIP_CONTENT:
        continue
    full = ROOT / relative
    try:
        value = full.read_text(encoding='utf-8')
    except (UnicodeDecodeError, OSError):
        errors.append(f'{label}: cannot scan this file as UTF-8')
        continue
    for description, pattern in SECRET_MARKERS:
        for hit in pattern.finditer(value):
            if description == 'email address' and hit.group(0) == 'git@github.com':
                continue  # SSH Git remote, not a user's email address
            line = value.count('\n', 0, hit.start()) + 1
            errors.append(f'{label}:{line}: possible {description}')
    # Only reserved example zones should appear in material that is intended to be copied.
    if label.startswith(('docs/', 'ansible/', 'opentofu/')) or label == 'README.md':
        for hit in re.finditer(r'\b(?:[a-z0-9-]+\.)+(?:us|home|lan|internal|local)\b', value, re.I):
            if not hit.group(0).endswith('.local'):
                line = value.count('\n', 0, hit.start()) + 1
                errors.append(f'{label}:{line}: review non-example domain')

if errors:
    print('Publication audit FAILED:')
    for e in errors:
        print(' -', e)
    sys.exit(1)
print(f'Publication audit PASSED ({len(files)} text/source files inspected).')
print('Still manually inspect git diff --cached and check all deployment-specific values.')
