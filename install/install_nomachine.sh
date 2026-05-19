#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "NoMachine 9.5.7 install start"

echo ""
echo "[1/6] Move to Downloads"
cd ~/Downloads

echo ""
echo "[2/6] Download NoMachine 9.5.7"
wget https://web9001.nomachine.com/download/9.5/Linux/nomachine_9.5.7_2_amd64.deb

echo ""
echo "[3/6] Install NoMachine"
sudo apt install -y ./nomachine_9.5.7_2_amd64.deb

echo ""
echo "[4/6] Check NoMachine service"
sudo systemctl status nxserver --no-pager

echo ""
echo "[5/6] Show current server IP"
hostname -I

echo ""
echo "[6/6] Check NVIDIA GPU"
nvidia-smi || true

banner "NoMachine 9.5.7 install complete"

echo ""
echo "Connect with:"
echo "  nx://<server-ip>:4000"

echo ""
echo "Example:"
echo "  nx://192.168.0.10:4000"
