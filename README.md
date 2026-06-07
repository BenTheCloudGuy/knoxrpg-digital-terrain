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

## Prepare a Raspberry Pi

Run the setup script on the Pi before starting the app:

```sh
chmod +x scripts/prepare_pi.sh
./scripts/prepare_pi.sh
```

This installs Node.js 20, npm, the project dependencies, and the required local data/upload folders for the app.
