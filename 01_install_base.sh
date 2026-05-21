#!/bin/bash
set -e

echo "기본 시스템 및 NVIDIA 드라이버 설치 시작"
echo "[1/4] apt 업데이트 및 패키지 업그레이드"
sudo apt update
sudo apt upgrade -y

echo "[2/4] 기본 패키지 설치"
sudo apt install -y \
    build-essential \
    linux-tools-common \
    linux-tools-generic \
    xubuntu-desktop \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    unzip \
    wget \
    curl

echo "[3/4] CPU 성능 모드로 설정"
if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt --vm --quiet; then
    echo "VM 환경이므로 CPU performance 설정을 건너뜁니다."
else
    bash install/set-cpu-performance.sh
fi

echo "[4/4] NVIDIA 드라이버 설치"
ubuntu-drivers devices
sudo ubuntu-drivers install nvidia:580

echo "기본 설치 완료. 이제 재부팅합니다."
sudo reboot
