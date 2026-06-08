# KnoxRPG Digital Terrain App

This project now includes:

- an Express API for map uploads, activation, deletion, and editing
- a React admin interface for managing maps and display controls
- a dedicated full-screen display page for the Raspberry Pi wall display

## Run locally

1. Install Node.js and npm on the machine.
2. From the project root, run:
   - `npm install`
   - `cd client && npm install`
   - `cd .. && npm run dev`
3. Open the admin interface at `http://localhost:5173`.
4. Open the display page at `http://localhost:5173/display.html` or the built path after `npm run build`.

For the deployed Raspberry Pi runtime, the admin page is served on `http://localhost:3001/` on the Pi itself, or on the Pi LAN address such as `http://192.168.137.181:3001/` from another machine on the same network.

## Set up a Raspberry Pi

Run the setup script once on a fresh Pi (or any time you want to reset systemd units and OS-level config):

```sh
sudo bash scripts/setup.sh
sudo reboot
```

This installs Node.js + Chromium + build tools, installs npm dependencies, builds the React client, installs the udev rule that prevents the labwc compositor from rendering a mouse cursor on the kiosk display (the HDMI CEC ignore rule), and creates the `knoxrpg-digital-terrain` (API) and `knoxrpg-digital-terrain-display` (kiosk Chromium) systemd services. Re-running is safe.

## Update the application on the Raspberry Pi

After pulling new code, run the restart script. It refreshes npm dependencies, rebuilds the client, self-heals OS-level config if needed, and restarts both services:

```sh
cd /home/benthebuilder/knoxrpg-digital-terrain
git pull
sudo bash scripts/restart.sh
```

If the restart script reports that OS-level config was reinstalled, reboot the Pi so labwc picks up the change.
