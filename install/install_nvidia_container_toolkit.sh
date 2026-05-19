#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "NVIDIA Container Toolkit install start"

echo ""
echo "[1/8] Verify NVIDIA driver"
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi
else
    echo "NVIDIA driver is not installed."
    exit 1
fi

echo ""
echo "[2/8] Verify Docker"
if command -v docker >/dev/null 2>&1; then
    docker --version
else
    echo "Docker is not installed."
    exit 1
fi

echo ""
echo "[3/8] Add NVIDIA GPG key"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

echo ""
echo "[4/8] Add NVIDIA repository"
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

echo ""
echo "[5/8] Update apt"
sudo apt update

echo ""
echo "[6/8] Install NVIDIA Container Toolkit"
sudo apt install -y nvidia-container-toolkit

echo ""
echo "[7/8] Configure Docker runtime"
sudo nvidia-ctk runtime configure --runtime=docker

echo ""
echo "[8/8] Restart Docker"
sudo systemctl restart docker

banner "Install complete"

echo ""
echo "Test command:"
echo "docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi"

echo ""
echo "Or:"
echo "docker run --rm --gpus all ubuntu nvidia-smi"
