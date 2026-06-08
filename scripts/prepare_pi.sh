#!/usr/bin/env bash
set -euo pipefail

echo "[1/5] Updating system packages..."
sudo apt-get update
sudo apt-get install -y curl git build-essential python3 chromium

echo "[2/5] Installing the latest stable Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
if command -v node >/dev/null 2>&1; then
  echo "Current Node.js version before upgrade: $(node -v)"
fi
sudo apt-get install -y nodejs
if command -v node >/dev/null 2>&1; then
  echo "Node.js version after upgrade: $(node -v)"
  echo "npm version after upgrade: $(npm -v)"
fi

echo "[3/5] Verifying npm..."
node -v
npm -v

echo "[4/5] Installing project dependencies..."
cd "$(dirname "$0")/.."
npm install
cd client
npm install

echo "[5/5] Creating upload and data directories..."
mkdir -p ../uploads ../data

echo "Preparation complete."
echo "Run: npm run dev"
