#!/usr/bin/env bash
set -euo pipefail

echo "[1/5] Updating system packages..."
sudo apt-get update
sudo apt-get install -y curl git build-essential python3

echo "[2/5] Installing Node.js 20 LTS via NodeSource..."
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "Node.js is already installed: $(node -v)"
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
