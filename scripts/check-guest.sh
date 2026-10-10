#!/usr/bin/env bash
set -euo pipefail
cd /opt/openclaw
printf '\n== Docker Compose ==\n'
docker compose ps
printf '\n== Docker published ports (expected: 127.0.0.1:18789) ==\n'
docker compose port openclaw-gateway 18789
printf '\n== Gateway reachability (unauthenticated route may return 401) ==\n'
curl -sS -o /dev/null -w 'HTTP %{http_code}\n' http://127.0.0.1:18789/ || true
printf '\n== Recent logs ==\n'
docker compose logs --tail 35 openclaw-gateway
