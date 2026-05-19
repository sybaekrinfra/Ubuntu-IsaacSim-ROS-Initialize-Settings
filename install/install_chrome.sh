#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "Google Chrome install start"

echo ""
echo "[1/6] Move to Downloads"
cd ~/Downloads

echo ""
echo "[2/6] Download Google Chrome"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

echo ""
echo "[3/6] Install Google Chrome"
sudo apt install -y ./google-chrome-stable_current_amd64.deb

echo ""
echo "[4/6] Verify installation"
google-chrome --version

echo ""
echo "[5/6] Default browser note"
echo "If needed, choose Chrome in Settings > Default Applications."

echo ""
echo "[6/6] Finish"
echo "Run:"
echo "  google-chrome"

banner "Google Chrome install complete"
