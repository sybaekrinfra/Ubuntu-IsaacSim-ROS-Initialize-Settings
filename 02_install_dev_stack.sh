#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "개발 환경 설치 시작"

echo ""
echo "[1/8] NVIDIA 드라이버 확인"
nvidia-smi

echo ""
echo "[2/8] VSCode 설치"
bash install/install_vscode.sh

echo ""
echo "[3/8] Chrome 설치"
bash install/install_chrome.sh

echo ""
echo "[4/8] NoMachine 설치"
bash install/install_nomachine.sh

echo ""
echo "[5/8] Docker 설치"
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sudo ./get-docker.sh
sudo usermod -aG docker "${USER}"

echo ""
echo "[6/8] ROS 2 설치"
bash install/install_ros2.sh

echo ""
echo "[7/8] NVIDIA Container Toolkit 설치"
bash install/install_nvidia_container_toolkit.sh

echo ""
echo "[8/8] Isaac Sim 및 바탕화면 바로가기 설정"
bash install/install_isaacsim.sh
bash install/copy_files.sh

banner "개발 환경 설치 완료. 이제 재부팅합니다."
sudo reboot
