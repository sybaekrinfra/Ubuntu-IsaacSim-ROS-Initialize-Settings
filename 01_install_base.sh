#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "기본 시스템 및 NVIDIA 드라이버 설치 시작"

echo ""
echo "[1/4] apt 업데이트 및 패키지 업그레이드"
sudo apt update
sudo apt upgrade -y

echo ""
echo "[2/4] 기본 패키지 설치"
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
echo "[3/4] CPU 성능 모드로 설정"
sudo cpupower frequency-set -g performance || true

echo ""
echo "[4/4] NVIDIA 드라이버 설치"
ubuntu-drivers devices
sudo apt update
sudo apt install -y nvidia-driver-580

banner "기본 설치 완료. 이제 재부팅합니다."
sudo reboot
