#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_NAME="knoxrpg-digital-terrain"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo." >&2
  exit 1
fi

cd "$PROJECT_DIR"

echo "[1/4] Installing Node.js, npm, and Chromium..."
curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
apt-get update
apt-get install -y nodejs git build-essential python3 chromium x11-apps

echo "[2/4] Installing project dependencies..."
npm install
cd client
npm install
cd "$PROJECT_DIR"

echo "[2.5/4] Building the React client for production..."
npm run build

echo "[2.7/4] Installing blank Xcursor theme for the kiosk user..."
chmod +x "${PROJECT_DIR}/scripts/install_blank_cursor.sh"
runuser -u "${SUDO_USER:-pi}" -- bash "${PROJECT_DIR}/scripts/install_blank_cursor.sh"

echo "[3/4] Creating systemd services..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=KnoxRPG Digital Terrain App
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${PROJECT_DIR}
ExecStart=/usr/bin/env bash -lc 'cd "${PROJECT_DIR}" && npm run build && npm run start'
Restart=always
RestartSec=5
User=${SUDO_USER:-pi}
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=PORT=3001
StandardOutput=append:${PROJECT_DIR}/logs/app.log
StandardError=append:${PROJECT_DIR}/logs/app.log

[Install]
WantedBy=multi-user.target
EOF

DISPLAY_SERVICE_FILE="/etc/systemd/system/knoxrpg-digital-terrain-display.service"
cat > "$DISPLAY_SERVICE_FILE" <<EOF
[Unit]
Description=KnoxRPG Digital Terrain Display
After=network-online.target graphical.target ${SERVICE_NAME}.service
Wants=network-online.target graphical.target ${SERVICE_NAME}.service

[Service]
Type=simple
User=${SUDO_USER:-pi}
WorkingDirectory=${PROJECT_DIR}
Environment=DISPLAY=:0
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u ${SUDO_USER:-pi})
ExecStart=${PROJECT_DIR}/scripts/start_display.sh
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
EOF

chmod +x "${PROJECT_DIR}/scripts/start_display.sh"
mkdir -p "$PROJECT_DIR/logs"
chown -R "${SUDO_USER:-pi}:${SUDO_USER:-pi}" "$PROJECT_DIR"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl enable "knoxrpg-digital-terrain-display.service"
systemctl restart "$SERVICE_NAME"

printf '\n[4/4] Services are enabled and running.\n'
systemctl status "$SERVICE_NAME" --no-pager
printf '\nDisplay service status:\n'
systemctl status "knoxrpg-digital-terrain-display.service" --no-pager || true

cat <<'BANNER'

================================================================
 REBOOT REQUIRED to finish setup.

 The blank Xcursor theme was written to ~/.config/labwc/environment,
 but the labwc Wayland compositor only picks up new XCURSOR_* values
 at session start. Run:

     sudo reboot

 After reboot, the kiosk display should come up with no visible
 cursor and no keyring unlock prompt.
================================================================
BANNER
