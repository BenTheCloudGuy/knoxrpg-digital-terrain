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

echo "[1/4] Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
apt-get update
apt-get install -y nodejs git build-essential python3

echo "[2/4] Installing project dependencies..."
npm install
cd client
npm install
cd "$PROJECT_DIR"

echo "[3/4] Creating systemd service..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=KnoxRPG Digital Terrain App
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${PROJECT_DIR}
ExecStart=/usr/bin/npm run start
Restart=always
RestartSec=5
User=${SUDO_USER:-pi}
Environment=PORT=3001
StandardOutput=append:${PROJECT_DIR}/logs/app.log
StandardError=append:${PROJECT_DIR}/logs/app.log

[Install]
WantedBy=multi-user.target
EOF

mkdir -p "$PROJECT_DIR/logs"
chown -R "${SUDO_USER:-pi}:${SUDO_USER:-pi}" "$PROJECT_DIR"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

echo "[4/4] Service is enabled and running."
systemctl status "$SERVICE_NAME" --no-pager
