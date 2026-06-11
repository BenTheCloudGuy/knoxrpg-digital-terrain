# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.0.19] - 2026-06-11

### Changed
- Rewrote README with proper project overview, quick-start instructions, architecture summary, and development setup.

## [1.0.18] - 2026-06-08

### Changed
- Consolidated the Pi-side install scripts. `prepare_pi.sh`, `install_and_run.sh`, `restart_kdt.sh`, `install_blank_cursor.sh`, and `install_hdmi_cec_ignore.sh` are replaced by two scripts:
  - `scripts/setup.sh` — one-shot fresh-Pi setup: OS packages, npm dependencies, client build, HDMI CEC udev rule, both systemd services. Run with `sudo bash scripts/setup.sh` then reboot.
  - `scripts/restart.sh` — post-`git pull`: refreshes dependencies, rebuilds the client, self-heals the CEC udev rule if missing, and restarts both services. Run with `sudo bash scripts/restart.sh`.
- Dropped the blank Xcursor theme workaround entirely. The real fix is removing pointer capability from labwc's seat via the CEC udev rule, so the cursor-theme machinery (1.0.10–1.0.16) is no longer needed.
- Updated README, copilot-instructions, and the VS Code `Validate shell scripts` task to reference the new scripts.

## [1.0.17] - 2026-06-08

### Fixed
- Identified the real source of the persistent cursor on the kiosk display: the Pi's `vc4-hdmi-0` and `vc4-hdmi-1` outputs are registered with libinput as keyboard + pointer devices (CEC remote-control signals from connected monitors), which causes labwc to enable pointer capability on its seat and render a default cursor even though no real mouse is attached. The blank Xcursor theme work in 1.0.14–1.0.16 only masked the symptom and was repeatedly defeated by labwc's built-in fallback arrow.
- Added `scripts/install_hdmi_cec_ignore.sh`, which installs `/etc/udev/rules.d/70-knoxrpg-ignore-hdmi-cec.rules` to tell libinput to ignore any input device named `vc4-hdmi-?`. With these devices removed from seat0, labwc has no pointer capability and never renders a cursor. Verified live on the Pi: `libinput list-devices` now shows only `pwr_button` (keyboard-only), and the kiosk display has no visible cursor after reboot.
- Wired the new installer into `install_and_run.sh`, `prepare_pi.sh`, and `restart_kdt.sh` (self-heal) so the rule is recreated on fresh installs and recovered if it ever goes missing. The blank Xcursor theme is kept as defense-in-depth in case a future Pi OS release re-introduces a different fake pointer source.

## [1.0.16] - 2026-06-08

### Fixed
- The blank Xcursor theme installed in 1.0.15 only contained a 1x1 transparent cursor image. labwc's wlroots cursor renderer rejected the undersized image and fell back to its built-in arrow, so the kiosk display continued to show a visible pointer even though `XCURSOR_THEME=blank` was active. `install_blank_cursor.sh` now generates fully transparent RGBA PNGs at the standard sizes (16/24/32/48/64) and packs them into a single multi-size cursor so labwc accepts the theme and renders nothing visible. Verified by inspecting the rendered cursor in a `grim -c` screenshot of the live kiosk display, which previously showed the labwc fallback arrow.

## [1.0.15] - 2026-06-07

### Fixed
- The blank Xcursor theme was being installed to `~/.icons/blank/` and the env vars to `~/.config/labwc/environment`, but the Raspberry Pi OS `labwc-pi` wrapper ignores both of those locations entirely. It only reads `/etc/xdg/labwc/environment`, which ships with `XCURSOR_THEME=PiXtrix` and `XCURSOR_SIZE=24` hardcoded. Reworked `install_blank_cursor.sh` to install the theme system-wide under `/usr/share/icons/blank/` and to patch the system labwc environment file in place (with a one-time backup at `/etc/xdg/labwc/environment.bak.knoxrpg` for easy revert). Verified working on Pi: live `grim` screenshot of the kiosk display shows no cursor anywhere on screen.
- `install_and_run.sh`, `prepare_pi.sh`, and `restart_kdt.sh` updated to invoke the cursor installer as root (it now requires write access to `/usr/share/icons` and `/etc/xdg/labwc`). The `restart_kdt.sh` self-heal check now looks at `/usr/share/icons/blank/cursors` and also re-runs the installer if `/etc/xdg/labwc/environment` is not pointing at the blank theme, so future labwc/Pi-OS updates that restore the default cursor are caught automatically.
- Marked `scripts/install_blank_cursor.sh` executable in the git index (was committed without the +x bit on its first add, which caused `sudo .../install_blank_cursor.sh` to fail with `command not found` on the Pi after `git pull`).

## [1.0.14] - 2026-06-07

### Fixed
- The base64-embedded 1x1 transparent PNG inside `install_blank_cursor.sh` was malformed; `xcursorgen` reported `PNG error while reading blank.png` and `set -e` aborted the rest of the installer (leaving a stub cursor file, no cursor-name symlinks, and an untouched `~/.config/labwc/environment`). Replaced the embedded base64 with a tiny inline `python3` snippet that builds a byte-perfect 67-byte 1x1 transparent RGBA PNG from the PNG spec, so the installer now consistently produces the 70+ symlinks and writes the `XCURSOR_THEME`/`XCURSOR_SIZE` lines.

## [1.0.13] - 2026-06-07

### Changed
- `install_and_run.sh` now `chmod +x`s the cursor installer before invoking it and prints a clear "REBOOT REQUIRED" banner at the end so fresh deployments do not skip the labwc relaunch step that activates `XCURSOR_THEME`/`XCURSOR_SIZE`.
- `restart_kdt.sh` is now self-healing for existing installs: if `~/.icons/blank/cursors` is missing, it installs `x11-apps` (if needed) and runs the blank-cursor installer as the kiosk user, then warns that a reboot is required for labwc to pick up the new env vars. Service restarts still happen as before.

## [1.0.12] - 2026-06-07

### Fixed
- Suppressed the GNOME keyring unlock prompt that appeared on the kiosk display after a reboot by launching Chromium with `--password-store=basic` and `--use-mock-keychain`. The kiosk has no need to persist secrets in the system keyring, so this avoids the Secret Service path entirely. Also disabled the unused `GlobalMediaControls` and `MediaRouter` features to keep extra dialogs from surfacing.

## [1.0.11] - 2026-06-07

### Added
- New `scripts/install_blank_cursor.sh` installer that generates a fully transparent Xcursor theme (`blank`) under the kiosk user's `~/.icons/`, symlinks every common cursor name to it, and writes `XCURSOR_THEME=blank` / `XCURSOR_SIZE=1` to `~/.config/labwc/environment`. This hides the pointer at the labwc compositor level, which is where the Wayland session actually draws it.
- `prepare_pi.sh` and `install_and_run.sh` now install `x11-apps` (for `xcursorgen`) and invoke the new installer as part of the Pi prep flow.

### Removed
- Dropped the `unclutter` install + launcher invocation and the `xsetroot -cursor_name none` call from `scripts/start_display.sh`. Both target X11 only and are ignored by the labwc/Wayland compositor on Debian 13, so they were producing no effect.
- Removed the data-URI SVG cursor on the display page in favor of a plain `cursor: none !important` rule; the compositor-level theme is now the real fix and the CSS rule only needs to cover non-Pi browsers.

### Fixed
- `prepare_pi.sh` now also runs `npm run build` before declaring success so the server's catch-all has a `client/dist` to serve.

## [1.0.10] - 2026-06-07

### Fixed
- Replaced the body-only `cursor: none` rule on the full-screen display with a universal selector backed by a 1x1 transparent SVG cursor so the pointer stays hidden over images, video, and any focused element regardless of the underlying browser or compositor default. Removed the redundant JavaScript cursor handlers that were trying to paper over the same issue.

## [1.0.9]

### Fixed
- Increased the upload limit for media files so larger MP4/WEBM maps no longer fail with file-size errors.
- Made the Pi restart helper use non-interactive npm commands so the update path completes reliably on the remote host.
- Updated the map library layout to stack cards top-to-bottom with consistent sizing and fixed the video-control polling path used by Play/Pause actions.
- Hid the display-page cursor on launch so the full-screen main display stays clean.
- Added an X11 cursor-hide step to the Pi Chromium launcher so the pointer stays invisible in kiosk mode.
- Added the X11 cursor-hiding utility to the Pi setup path and kiosk launcher for a reliable hidden-pointer display on startup.
- Prevented Git refreshes from overwriting uploaded map data by excluding runtime data files from version control.
- Restored the Pi runtime startup path by fixing the display launcher and documenting the dependency/build requirement for `npm run build`.

## [1.0.2] - 2026-06-08

### Fixed
- Protected uploaded map data and media files from being wiped by pull/update operations.

## [1.0.1] - 2026-06-08

### Fixed
- Replaced the browser prompt-based map edit flow with an in-page edit dialog so the Edit button works in the admin interface.

### Changed
- Added server-backed display control syncing to support the Pi display path more reliably.

## [1.0.0] - 2026-06-07

### Added
- Initial release of the KnoxRPG Digital Terrain application.
- Project documentation and setup guidance.
