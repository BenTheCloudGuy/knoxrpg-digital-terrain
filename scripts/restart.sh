#!/usr/bin/env bash
# KnoxRPG Digital Terrain - post-update restart.
#
# Run after `git pull` to apply code changes:
#
#   sudo bash scripts/restart.sh
#
# This script:
#   1. Refreshes root + client npm dependencies and rebuilds the client.
#   2. Self-heals OS-level config:
#        - the HDMI CEC udev rule (removes the kiosk-display cursor)
#      If something is missing it is reinstalled and the user is told
#      a reboot is required for labwc to pick up the change.
#   3. Restarts both systemd services and prints status.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo." >&2
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_USER="${SUDO_USER:-pi}"
SERVICE_NAME="knoxrpg-digital-terrain"
DISPLAY_SERVICE="${SERVICE_NAME}-display"
CEC_RULE_FILE="/etc/udev/rules.d/70-knoxrpg-ignore-hdmi-cec.rules"
CEC_RULE_CONTENT='SUBSYSTEM=="input", ATTRS{name}=="vc4-hdmi-?", ENV{LIBINPUT_IGNORE_DEVICE}="1"'

cd "$PROJECT_DIR"

printf 'Refreshing npm dependencies and rebuilding the client...\n'
mkdir -p "$PROJECT_DIR/uploads" "$PROJECT_DIR/data" "$PROJECT_DIR/logs"
chown -R "$APP_USER:$APP_USER" "$PROJECT_DIR"
runuser -u "$APP_USER" -- env \
  npm_config_progress=false \
  npm_config_audit=false \
  npm_config_fund=false \
  bash -lc "cd '$PROJECT_DIR' && npm install --no-audit --no-fund --no-progress && cd client && npm install --no-audit --no-fund --no-progress && cd '$PROJECT_DIR' && npm run build"

REBOOT_REQUIRED=0
if [ ! -f "$CEC_RULE_FILE" ] || ! grep -qF "$CEC_RULE_CONTENT" "$CEC_RULE_FILE"; then
  printf 'HDMI CEC udev rule missing; installing...\n'
  printf '%s\n' "$CEC_RULE_CONTENT" > "$CEC_RULE_FILE"
  udevadm control --reload
  udevadm trigger --subsystem-match=input
  REBOOT_REQUIRED=1
fi

printf 'Restarting KnoxRPG Digital Terrain services...\n'
systemctl restart "$SERVICE_NAME"
systemctl restart "$DISPLAY_SERVICE"

printf '\nStatus:\n'
systemctl --no-pager status "$SERVICE_NAME" "$DISPLAY_SERVICE" || true

if [ "$REBOOT_REQUIRED" -eq 1 ]; then
  cat <<'BANNER'

================================================================
 OS-level config changed. Reboot the Pi so labwc rebuilds its
 seat without pointer capability:

     sudo reboot

================================================================
BANNER
fi
