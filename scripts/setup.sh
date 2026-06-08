#!/usr/bin/env bash
# KnoxRPG Digital Terrain - one-shot Raspberry Pi setup.
#
# Run once on a fresh Pi (or any time you want to reset systemd units
# and OS-level config). Re-running is safe.
#
#   sudo bash scripts/setup.sh
#
# This script:
#   1. Installs OS packages (Node.js, npm, Chromium, build tools).
#   2. Installs root + client npm dependencies and builds the React client.
#   3. Installs the udev rule that makes libinput ignore the HDMI CEC
#      pseudo-input devices (vc4-hdmi-*). Those devices appear as a
#      keyboard + pointer on seat0 even with no real input attached,
#      which is what made labwc render a mouse cursor on the kiosk
#      display. Removing them removes the cursor.
#   4. Creates and enables the API + kiosk display systemd services.
#   5. Prints a "REBOOT REQUIRED" banner; reboot to let labwc rebuild
#      its seat without pointer capability.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo." >&2
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_USER="${SUDO_USER:-pi}"
APP_UID="$(id -u "$APP_USER")"
SERVICE_NAME="knoxrpg-digital-terrain"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
DISPLAY_SERVICE="${SERVICE_NAME}-display"
DISPLAY_SERVICE_FILE="/etc/systemd/system/${DISPLAY_SERVICE}.service"
CEC_RULE_FILE="/etc/udev/rules.d/70-knoxrpg-ignore-hdmi-cec.rules"
CEC_RULE_CONTENT='SUBSYSTEM=="input", ATTRS{name}=="vc4-hdmi-?", ENV{LIBINPUT_IGNORE_DEVICE}="1"'

cd "$PROJECT_DIR"

echo "[1/5] Installing OS packages (Node.js, Chromium, build tools)..."
curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
apt-get update
apt-get install -y nodejs git build-essential python3 chromium

echo "[2/5] Installing project dependencies and building the React client..."
runuser -u "$APP_USER" -- env \
  npm_config_progress=false \
  npm_config_audit=false \
  npm_config_fund=false \
  bash -lc "cd '$PROJECT_DIR' && npm install --no-audit --no-fund --no-progress && cd client && npm install --no-audit --no-fund --no-progress && cd '$PROJECT_DIR' && npm run build"

echo "[3/5] Installing HDMI CEC ignore udev rule..."
if [ ! -f "$CEC_RULE_FILE" ] || ! grep -qF "$CEC_RULE_CONTENT" "$CEC_RULE_FILE"; then
  printf '%s\n' "$CEC_RULE_CONTENT" > "$CEC_RULE_FILE"
  echo "  wrote $CEC_RULE_FILE"
fi
udevadm control --reload
udevadm trigger --subsystem-match=input

echo "[4/5] Creating systemd services..."
mkdir -p "$PROJECT_DIR/logs" "$PROJECT_DIR/uploads" "$PROJECT_DIR/data"
chown -R "$APP_USER:$APP_USER" "$PROJECT_DIR"
chmod +x "$PROJECT_DIR/scripts/start_display.sh"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=KnoxRPG Digital Terrain App
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${PROJECT_DIR}
ExecStart=/usr/bin/env bash -lc 'cd "${PROJECT_DIR}" && npm run start'
Restart=always
RestartSec=5
User=${APP_USER}
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=PORT=3001
StandardOutput=append:${PROJECT_DIR}/logs/app.log
StandardError=append:${PROJECT_DIR}/logs/app.log

[Install]
WantedBy=multi-user.target
EOF

cat > "$DISPLAY_SERVICE_FILE" <<EOF
[Unit]
Description=KnoxRPG Digital Terrain Display
After=network-online.target graphical.target ${SERVICE_NAME}.service
Wants=network-online.target graphical.target ${SERVICE_NAME}.service

[Service]
Type=simple
User=${APP_USER}
WorkingDirectory=${PROJECT_DIR}
Environment=DISPLAY=:0
Environment=XDG_RUNTIME_DIR=/run/user/${APP_UID}
ExecStart=${PROJECT_DIR}/scripts/start_display.sh
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl enable "$DISPLAY_SERVICE"
systemctl restart "$SERVICE_NAME"

echo "[5/5] Done. Service status:"
systemctl --no-pager status "$SERVICE_NAME" "$DISPLAY_SERVICE" || true

cat <<'BANNER'

================================================================
 REBOOT REQUIRED to finish setup.

 The HDMI CEC udev rule was installed, but labwc only re-evaluates
 its seat capabilities at session start. After reboot the kiosk
 display will come up with no visible cursor.

     sudo reboot

================================================================
BANNER
