#!/bin/bash
set -e

echo "Development stack install start"
echo "[1/9] Checking NVIDIA driver"
nvidia-smi

echo "[2/9] Installing VSCode"
bash install/install_vscode.sh

echo "[3/9] Installing Chrome"
bash install/install_chrome.sh

echo "[4/9] Installing Xfce Desktop and LightDM autologin"
bash install/install_desktop.sh

echo "[5/9] Installing Sunshine"
# Legacy remote desktop options (kept for reference, not used by default):
# bash install/legacy/install_xrdp.sh
# bash install/legacy/install_nm.sh
bash install/install_sunshine.sh

echo "[6/9] Installing Docker"
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sudo ./get-docker.sh
sudo usermod -aG docker "${USER}"

echo "[7/9] Installing ROS 2"
bash install/install_ros2.sh

echo "[8/9] Installing NVIDIA Container Toolkit"
bash install/install_nvidia_container_toolkit.sh

echo "[9/9] Installing Isaac Sim and desktop shortcuts"
bash install/install_isaacsim.sh
bash install/copy_files.sh

echo "Development stack install complete. Rebooting now."
sudo reboot
