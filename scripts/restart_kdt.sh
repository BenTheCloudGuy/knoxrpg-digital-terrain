#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo." >&2
  exit 1
fi

SYSTEMD_SERVICE="knoxrpg-digital-terrain.service"
DISPLAY_SERVICE="knoxrpg-digital-terrain-display.service"

printf 'Restarting KnoxRPG Digital Terrain services...\n'
systemctl restart "$SYSTEMD_SERVICE"
systemctl restart "$DISPLAY_SERVICE"

printf '\nStatus:\n'
systemctl --no-pager status "$SYSTEMD_SERVICE" "$DISPLAY_SERVICE" || true
