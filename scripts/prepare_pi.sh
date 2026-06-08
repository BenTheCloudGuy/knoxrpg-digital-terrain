#!/usr/bin/env bash
set -euo pipefail

echo "[1/6] Updating system packages..."
sudo apt-get update
sudo apt-get install -y curl git build-essential python3 chromium x11-apps

echo "[2/6] Installing the latest stable Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
if command -v node >/dev/null 2>&1; then
  echo "Current Node.js version before upgrade: $(node -v)"
fi
sudo apt-get install -y nodejs
if command -v node >/dev/null 2>&1; then
  echo "Node.js version after upgrade: $(node -v)"
  echo "npm version after upgrade: $(npm -v)"
fi

echo "[3/6] Verifying npm..."
node -v
npm -v

echo "[4/6] Installing project dependencies..."
cd "$(dirname "$0")/.."
npm install
cd client
npm install
cd ..

echo "[5/6] Building the React client for production..."
npm run build

echo "[6/6] Creating upload and data directories, installing blank cursor theme..."
mkdir -p uploads data
sudo bash scripts/install_blank_cursor.sh

echo "Preparation complete."
echo "Run: npm run dev (for local development) or use scripts/install_and_run.sh (for the Pi service install)."
