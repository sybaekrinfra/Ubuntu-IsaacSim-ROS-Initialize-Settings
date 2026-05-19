#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "NVIDIA Isaac Sim 5.1.0 설치 시작"

echo ""
echo "[1/7] Downloads 폴더로 이동"
cd ~/Downloads

echo ""
echo "[2/7] Isaac Sim 5.1.0 다운로드"
wget https://downloads.isaacsim.nvidia.com/isaac-sim-standalone-5.1.0-linux-x86_64.zip

echo ""
echo "[3/7] 설치 폴더 생성"
mkdir -p ~/isaacsim

echo ""
echo "[4/7] 압축 해제"
unzip isaac-sim-standalone-5.1.0-linux-x86_64.zip -d ~/isaacsim

echo ""
echo "[5/7] Isaac Sim 폴더로 이동"
cd ~/isaacsim

echo ""
echo "[6/7] 실행 권한 부여"
chmod +x *.sh

echo ""
echo "[7/7] post_install 실행"
./post_install.sh

banner "Isaac Sim 설치 완료"
