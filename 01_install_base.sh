#!/bin/bash
set -e

detect_ubuntu_codename() {
    . /etc/os-release
    echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}"
}

UBUNTU_CODENAME="$(detect_ubuntu_codename)"
XUBUNTU_DESKTOP_PACKAGE="xubuntu-desktop"

case "$UBUNTU_CODENAME" in
    noble|resolute)
        XUBUNTU_DESKTOP_PACKAGE="xubuntu-desktop-minimal"
        ;;
esac

echo "Ubuntu codename: ${UBUNTU_CODENAME}, using package: ${XUBUNTU_DESKTOP_PACKAGE}"

echo "기본 시스템 및 NVIDIA 드라이버 설치 시작"
echo "[1/5] apt 업데이트 및 패키지 업그레이드"
sudo apt update
sudo apt upgrade -y

echo "[2/5] 기본 패키지 설치"
sudo apt install -y \
    build-essential \
    linux-tools-common \
    linux-tools-generic \
    "$XUBUNTU_DESKTOP_PACKAGE" \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    unzip \
    wget \
    curl

echo "[3/5] CPU 성능 모드로 설정"
if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt --vm --quiet; then
    echo "VM 환경이므로 CPU performance 설정을 건너뜁니다."
else
    bash install/set-cpu-performance.sh
fi

echo "[4/5] NVIDIA 드라이버 설치"
ubuntu-drivers devices
sudo ubuntu-drivers install nvidia:580

echo "[5/5] 한글 입력기 ibus-hangul 설치"
sudo apt install ibus-hangul

echo "기본 설치 완료. 이제 재부팅합니다."
sudo reboot
