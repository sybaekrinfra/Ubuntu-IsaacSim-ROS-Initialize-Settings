#!/bin/bash
set -e

echo "NVIDIA Isaac Sim 5.1.0 설치 시작"
echo "[1/7] Downloads 폴더로 이동"
cd ~/Downloads

echo "[2/7] Isaac Sim 5.1.0 다운로드"
wget https://downloads.isaacsim.nvidia.com/isaac-sim-standalone-5.1.0-linux-x86_64.zip

echo "[3/7] 설치 폴더 생성"
mkdir -p ~/isaacsim

echo "[4/7] 압축 해제"
unzip isaac-sim-standalone-5.1.0-linux-x86_64.zip -d ~/isaacsim

echo "[5/7] Isaac Sim 폴더로 이동"
cd ~/isaacsim

echo "[6/7] 실행 권한 부여"
chmod +x *.sh

echo "[7/7] post_install 실행"
./post_install.sh

echo "Isaac Sim 설치 완료"
