#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "NoMachine 9.5.7 설치 시작"

echo ""
echo "[1/6] Downloads 폴더로 이동"
cd ~/Downloads

echo ""
echo "[2/6] NoMachine 9.5.7 다운로드"
wget https://web9001.nomachine.com/download/9.5/Linux/nomachine_9.5.7_2_amd64.deb

echo ""
echo "[3/6] NoMachine 설치"
sudo apt install -y ./nomachine_9.5.7_2_amd64.deb

echo ""
echo "[4/6] NoMachine 서비스 상태 확인"
sudo systemctl status nxserver --no-pager

echo ""
echo "[5/6] 현재 서버 IP 확인"
hostname -I

echo ""
echo "[6/6] NVIDIA GPU 확인"
nvidia-smi || true

banner "NoMachine 9.5.7 설치 완료"

echo ""
echo "접속 방법:"
echo "  nx://<서버IP>:4000"

echo ""
echo "예시:"
echo "  nx://192.168.0.10:4000"
