#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "NVIDIA Container Toolkit 설치 시작"

echo ""
echo "[1/8] NVIDIA 드라이버 확인"
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi
else
    echo "NVIDIA 드라이버가 설치되어 있지 않습니다."
    exit 1
fi

echo ""
echo "[2/8] Docker 확인"
if command -v docker >/dev/null 2>&1; then
    docker --version
else
    echo "Docker가 설치되어 있지 않습니다."
    exit 1
fi

echo ""
echo "[3/8] NVIDIA GPG 키 추가"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

echo ""
echo "[4/8] NVIDIA 저장소 추가"
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

echo ""
echo "[5/8] apt 업데이트"
sudo apt update

echo ""
echo "[6/8] NVIDIA Container Toolkit 설치"
sudo apt install -y nvidia-container-toolkit

echo ""
echo "[7/8] Docker 런타임 설정"
sudo nvidia-ctk runtime configure --runtime=docker

echo ""
echo "[8/8] Docker 재시작"
sudo systemctl restart docker

banner "설치 완료"

echo ""
echo "확인 명령어:"
echo "docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi"

echo ""
echo "또는"
echo "docker run --rm --gpus all ubuntu nvidia-smi"
