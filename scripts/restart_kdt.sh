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
runuser -u "$APP_USER" -- env \
  npm_config_progress=false \
  npm_config_audit=false \
  npm_config_fund=false \
  bash -lc "cd '$APP_DIR' && npm install --no-audit --no-fund --no-progress && cd client && npm install --no-audit --no-fund --no-progress && npm run build"

APP_HOME="$(getent passwd "$APP_USER" | cut -d: -f6)"
if [ ! -d /usr/share/icons/blank/cursors ] || ! grep -q '^XCURSOR_THEME=blank' /etc/xdg/labwc/environment 2>/dev/null; then
  printf 'Blank cursor theme missing or not applied; installing now...\n'
  if ! command -v xcursorgen >/dev/null 2>&1; then
    apt-get update
    apt-get install -y x11-apps
  fi
  chmod +x "$APP_DIR/scripts/install_blank_cursor.sh"
  bash "$APP_DIR/scripts/install_blank_cursor.sh"
  printf 'Cursor theme installed. A reboot is required for labwc to pick up XCURSOR_* env vars.\n'
fi

printf 'Restarting KnoxRPG Digital Terrain services...\n'
systemctl restart "$SYSTEMD_SERVICE"
systemctl restart "$DISPLAY_SERVICE"

printf '\nStatus:\n'
systemctl --no-pager status "$SYSTEMD_SERVICE" "$DISPLAY_SERVICE" || true
