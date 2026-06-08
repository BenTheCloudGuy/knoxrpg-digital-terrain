#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo." >&2
  exit 1
fi

SYSTEMD_SERVICE="knoxrpg-digital-terrain.service"
DISPLAY_SERVICE="knoxrpg-digital-terrain-display.service"
APP_DIR="/home/benthebuilder/knoxrpg-digital-terrain"
APP_USER="benthebuilder"

printf 'Refreshing runtime dependencies for %s...\n' "$APP_USER"
mkdir -p "$APP_DIR/uploads" "$APP_DIR/data" "${APP_DIR}/logs"
chown -R "$APP_USER:$APP_USER" "$APP_DIR"
runuser -u "$APP_USER" -- bash -lc "cd '$APP_DIR' && npm install && cd client && npm install && npm run build"

printf 'Restarting KnoxRPG Digital Terrain services...\n'
systemctl restart "$SYSTEMD_SERVICE"
systemctl restart "$DISPLAY_SERVICE"

printf '\nStatus:\n'
systemctl --no-pager status "$SYSTEMD_SERVICE" "$DISPLAY_SERVICE" || true
