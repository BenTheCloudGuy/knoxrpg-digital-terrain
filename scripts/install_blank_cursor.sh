#!/usr/bin/env bash
set -euo pipefail

# Installs a fully transparent Xcursor theme for the target user so the labwc
# Wayland compositor draws no visible pointer. Run once per user account.
# Re-running is safe.

THEME_NAME="${THEME_NAME:-blank}"
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  echo "Could not resolve home directory for user '$TARGET_USER'." >&2
  exit 1
fi

if ! command -v xcursorgen >/dev/null 2>&1; then
  echo "xcursorgen is required (provided by the 'x11-apps' package). Install it first." >&2
  exit 1
fi

THEME_DIR="$TARGET_HOME/.icons/$THEME_NAME"
CURSORS_DIR="$THEME_DIR/cursors"
ENV_FILE="$TARGET_HOME/.config/labwc/environment"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# 1x1 fully transparent PNG, base64-encoded
cat > "$WORK_DIR/blank.png.b64" <<'PNG_B64'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYGD4DwABBAEAfbLI3wAAAABJRU5ErkJggg==
PNG_B64
base64 -d "$WORK_DIR/blank.png.b64" > "$WORK_DIR/blank.png"

printf '1 0 0 blank.png\n' > "$WORK_DIR/blank.cursor"

mkdir -p "$CURSORS_DIR"
xcursorgen "$WORK_DIR/blank.cursor" "$CURSORS_DIR/default"

cat > "$THEME_DIR/index.theme" <<EOF
[Icon Theme]
Name=$THEME_NAME
Comment=Fully transparent cursor for kiosk display
Inherits=core
EOF

# Alias every common cursor name to the blank one so no app can pull
# in a visible glyph from the inherited theme.
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

cd "$CURSORS_DIR"
for name in "${CURSOR_NAMES[@]}"; do
  ln -sf default "$name"
done

mkdir -p "$(dirname "$ENV_FILE")"
touch "$ENV_FILE"
# Drop any prior XCURSOR_* lines so re-running does not stack duplicates.
sed -i '/^XCURSOR_THEME=/d; /^XCURSOR_SIZE=/d' "$ENV_FILE"
printf 'XCURSOR_THEME=%s\nXCURSOR_SIZE=1\n' "$THEME_NAME" >> "$ENV_FILE"

chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.icons" "$TARGET_HOME/.config/labwc"

cat <<EOF
Installed blank cursor theme '$THEME_NAME' for user '$TARGET_USER'.
Wrote XCURSOR_THEME and XCURSOR_SIZE to: $ENV_FILE
Reboot the Pi (or log the user out of labwc) for the change to take effect.
EOF
