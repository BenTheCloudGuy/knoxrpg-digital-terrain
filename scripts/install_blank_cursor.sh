#!/usr/bin/env bash
set -euo pipefail

# Installs a fully transparent system-wide Xcursor theme so the labwc
# Wayland compositor on Raspberry Pi OS draws no visible pointer.
# Run once during Pi setup as the root user (or via sudo). Re-running
# is safe.

THEME_NAME="${THEME_NAME:-blank}"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO=sudo
else
  echo "This script must be run as root or with sudo available." >&2
  exit 1
fi

if ! command -v xcursorgen >/dev/null 2>&1; then
  echo "xcursorgen is required (provided by the 'x11-apps' package). Install it first." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to generate the transparent cursor PNG." >&2
  exit 1
fi

THEME_DIR="/usr/share/icons/$THEME_NAME"
CURSORS_DIR="$THEME_DIR/cursors"
SYSTEM_ENV_FILE="/etc/xdg/labwc/environment"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Generate a known-good 1x1 fully transparent RGBA PNG.
python3 - "$WORK_DIR/blank.png" <<'PY'
import struct, sys, zlib
def chunk(name, data):
    return (len(data).to_bytes(4, "big") + name + data
            + zlib.crc32(name + data).to_bytes(4, "big"))
png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00\x00"))
png += chunk(b"IEND", b"")
open(sys.argv[1], "wb").write(png)
PY

printf '1 0 0 blank.png\n' > "$WORK_DIR/blank.cursor"

( cd "$WORK_DIR" && xcursorgen blank.cursor blank-cursor.bin )

$SUDO install -d -m 0755 "$CURSORS_DIR"
$SUDO install -D -m 0644 "$WORK_DIR/blank-cursor.bin" "$CURSORS_DIR/default"

$SUDO tee "$THEME_DIR/index.theme" >/dev/null <<EOF
[Icon Theme]
Name=$THEME_NAME
Comment=Fully transparent cursor for kiosk display
Inherits=core
EOF

# Alias every common cursor name to the blank one so no app can pull in a
# visible glyph from the inherited theme. Covers X11 (left_ptr, fleur,
# ...) and CSS3 (pointer, grab, zoom-in, ...) names.
CURSOR_NAMES=(
  left_ptr top_left_arrow X_cursor arrow
  hand hand1 hand2 pointer pointing_hand
  xterm ibeam text
  watch wait progress left_ptr_watch
  crosshair cross crosshair_arrow
  fleur move all-scroll size_all
  sb_h_double_arrow sb_v_double_arrow
  ew-resize ns-resize col-resize row-resize
  n-resize s-resize e-resize w-resize
  ne-resize nw-resize se-resize sw-resize
  top_side bottom_side left_side right_side
  top_left_corner top_right_corner bottom_left_corner bottom_right_corner
  question_arrow help whats_this
  not-allowed forbidden no-drop circle
  grab grabbing openhand closedhand
  copy link alias
  dnd-move dnd-copy dnd-link dnd-no-drop dnd-none
  context-menu cell vertical-text zoom-in zoom-out
  pencil draft_small draft_large
)

for name in "${CURSOR_NAMES[@]}"; do
  $SUDO ln -sf default "$CURSORS_DIR/$name"
done

# On Raspberry Pi OS the labwc-pi wrapper reads only the system-level
# /etc/xdg/labwc/environment and ships with XCURSOR_THEME=PiXtrix /
# XCURSOR_SIZE=24 baked in there. The user-level
# ~/.config/labwc/environment is ignored by this wrapper, so the only
# reliable way to switch cursors is to patch this file. Backed up once
# on first run so the original can be restored.
if [ -f "$SYSTEM_ENV_FILE" ]; then
  if [ ! -f "${SYSTEM_ENV_FILE}.bak.knoxrpg" ]; then
    $SUDO cp "$SYSTEM_ENV_FILE" "${SYSTEM_ENV_FILE}.bak.knoxrpg"
  fi
  if grep -q '^XCURSOR_THEME=' "$SYSTEM_ENV_FILE"; then
    $SUDO sed -i "s|^XCURSOR_THEME=.*|XCURSOR_THEME=$THEME_NAME|" "$SYSTEM_ENV_FILE"
  else
    printf 'XCURSOR_THEME=%s\n' "$THEME_NAME" | $SUDO tee -a "$SYSTEM_ENV_FILE" >/dev/null
  fi
  if grep -q '^XCURSOR_SIZE=' "$SYSTEM_ENV_FILE"; then
    $SUDO sed -i 's|^XCURSOR_SIZE=.*|XCURSOR_SIZE=1|' "$SYSTEM_ENV_FILE"
  else
    printf 'XCURSOR_SIZE=1\n' | $SUDO tee -a "$SYSTEM_ENV_FILE" >/dev/null
  fi
  echo "Patched $SYSTEM_ENV_FILE (original backed up to ${SYSTEM_ENV_FILE}.bak.knoxrpg)."
else
  echo "Warning: $SYSTEM_ENV_FILE not present; cursor theme may not be applied." >&2
fi

cat <<EOF
Installed blank cursor theme '$THEME_NAME' to $THEME_DIR.
Reboot the Pi for the labwc compositor to pick up the new XCURSOR_* values.
EOF
