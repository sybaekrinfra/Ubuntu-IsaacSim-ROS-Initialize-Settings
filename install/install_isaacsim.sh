#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "NVIDIA Isaac Sim 5.1.0 install start"

echo ""
echo "[1/7] Move to Downloads"
cd ~/Downloads

echo ""
echo "[2/7] Download Isaac Sim 5.1.0"
wget https://downloads.isaacsim.nvidia.com/isaac-sim-standalone-5.1.0-linux-x86_64.zip

echo ""
echo "[3/7] Create install directory"
mkdir -p ~/isaacsim

echo ""
echo "[4/7] Extract archive"
unzip isaac-sim-standalone-5.1.0-linux-x86_64.zip -d ~/isaacsim

echo ""
echo "[5/7] Move into Isaac Sim directory"
cd ~/isaacsim

echo ""
echo "[6/7] Make shell scripts executable"
chmod +x *.sh

echo ""
echo "[7/7] Run post install"
./post_install.sh

banner "Isaac Sim install complete"
