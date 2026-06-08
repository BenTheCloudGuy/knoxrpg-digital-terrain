#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
HOST_IP="${HOST_IP:-127.0.0.1}"
DISPLAY_URL="${DISPLAY_URL:-http://${HOST_IP}:3001/display.html}"

cd "$PROJECT_DIR"

CHROMIUM_BIN="/usr/lib/chromium/chromium"
if [ ! -x "$CHROMIUM_BIN" ]; then
  if ! command -v chromium >/dev/null 2>&1; then
    echo "chromium is not installed. Run scripts/prepare_pi.sh or install chromium first." >&2
    exit 1
  fi
  CHROMIUM_BIN="$(command -v chromium)"
fi

export DISPLAY="${DISPLAY:-:0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"
export HOME="${HOME:-$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f6)}"

until curl -fsS http://127.0.0.1:3001/api/health >/dev/null 2>&1; do
  echo "Waiting for the KnoxRPG API to be ready..."
  sleep 2
 done

exec "$CHROMIUM_BIN" \
  --kiosk \
  --no-first-run \
  --noerrdialogs \
  --disable-infobars \
  --disable-session-crashed-bubble \
  --disable-dev-shm-usage \
  --start-fullscreen \
  --password-store=basic \
  --use-mock-keychain \
  --disable-features=GlobalMediaControls,MediaRouter \
  "$DISPLAY_URL"
