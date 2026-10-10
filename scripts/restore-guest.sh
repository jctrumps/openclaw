#!/usr/bin/env bash
# Run directly ON THE VM as root. Restores from trusted backup; OVERWRITES existing files.
set -euo pipefail
if [[ $EUID -ne 0 ]]; then echo 'Run with sudo'; exit 1; fi
ARCHIVE="${1:?Usage: sudo ./restore-guest.sh /path/to/openclaw-backup.tar.gz}"
[[ -f "$ARCHIVE" ]] || { echo 'Backup archive missing'; exit 1; }
echo 'STOP: This overwrites /opt/openclaw and /srv/openclaw on this VM.'
read -r -p 'Type RESTORE to continue: ' ANSWER
[[ "$ANSWER" == RESTORE ]] || exit 1
cd /opt/openclaw
docker compose stop openclaw-gateway || true
# Protect against malicious archive entries: use only archives created by this project.
tar -tzf "$ARCHIVE" | awk '$0 !~ /^(opt\/openclaw|srv\/openclaw)(\/|$)/ { print "Unexpected member: " $0; bad=1 } END { exit bad }'
tar -xzf "$ARCHIVE" -C /
chown -R ubuntu:ubuntu /opt/openclaw /srv/openclaw
docker compose up -d openclaw-gateway
echo 'Restore complete. Recheck OAuth, dashboard authentication and Docker health.'
