#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "Dev stack setup start"

echo ""
echo "[1/8] Verify NVIDIA driver"
nvidia-smi

echo ""
echo "[2/8] Install VSCode"
bash install/install_vscode.sh

echo ""
echo "[3/8] Install Chrome"
bash install/install_chrome.sh

echo ""
echo "[4/8] Install NoMachine"
bash install/install_nomachine.sh

echo ""
echo "[5/8] Install Docker"
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sudo ./get-docker.sh
sudo usermod -aG docker "${USER}"

echo ""
echo "[6/8] Install ROS 2 Jazzy"
bash install/install_ros2_jazzy.sh

echo ""
echo "[7/8] Install NVIDIA Container Toolkit"
bash install/install_nvidia_container_toolkit.sh

echo ""
echo "[8/8] Install Isaac Sim and desktop shortcuts"
bash install/install_isaacsim.sh
bash install/copy_files.sh

banner "Dev stack install complete. Rebooting now."
sudo reboot
