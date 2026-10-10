#!/usr/bin/env bash
# Run directly ON THE VM. Contains OAuth tokens, gateway token, and potentially GitHub credentials.
set -euo pipefail
if [[ $EUID -ne 0 ]]; then echo 'Run with sudo'; exit 1; fi
DEST="${1:-/root/openclaw-backups}"
mkdir -p "$DEST"
chmod 0700 "$DEST"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE="$DEST/openclaw-$STAMP.tar.gz"
# Stop the gateway for a consistent local state/config snapshot.
cd /opt/openclaw
docker compose stop openclaw-gateway
trap 'docker compose up -d openclaw-gateway' EXIT
tar --create --gzip --file "$ARCHIVE" --directory / opt/openclaw srv/openclaw
chmod 0600 "$ARCHIVE"
echo "Backup created: $ARCHIVE"
echo 'SECRET ARCHIVE: encrypt before copying off the VM, and never commit to Git.'
