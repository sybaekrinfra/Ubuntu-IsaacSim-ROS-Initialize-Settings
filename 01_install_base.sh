#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "Base + NVIDIA Driver setup start"

echo ""
echo "[1/4] Update apt and upgrade packages"
sudo apt update
sudo apt upgrade -y

echo ""
echo "[2/4] Install base packages"
sudo apt install -y \
    build-essential \
    linux-tools-common \
    linux-tools-generic \
    xubuntu-desktop-minimal \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    unzip \
    wget \
    curl

echo ""
echo "[3/4] Set CPU governor to performance"
sudo cpupower frequency-set -g performance || true

echo ""
echo "[4/4] Install NVIDIA driver"
ubuntu-drivers devices
sudo apt update
sudo apt install -y nvidia-driver-580

banner "Base install complete. Rebooting now."
sudo reboot
