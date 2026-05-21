#!/bin/bash
set -e

echo "Development stack install start"
echo "[1/8] Checking NVIDIA driver"
nvidia-smi

echo "[2/8] Installing VSCode"
bash install/install_vscode.sh

echo "[3/8] Installing Chrome"
bash install/install_chrome.sh

echo "[4/8] Installing NoMachine"
bash install/install_nomachine.sh

echo "[5/8] Installing Docker"
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sudo ./get-docker.sh
sudo usermod -aG docker "${USER}"

echo "[6/8] Installing ROS 2"
bash install/install_ros2.sh

echo "[7/8] Installing NVIDIA Container Toolkit"
bash install/install_nvidia_container_toolkit.sh

echo "[8/8] Installing Isaac Sim and desktop shortcuts"
bash install/install_isaacsim.sh
bash install/copy_files.sh

echo "Development stack install complete. Rebooting now."
sudo reboot
