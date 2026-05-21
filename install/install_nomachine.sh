#!/bin/bash
set -e

echo "NoMachine 9.5.7 설치 시작"
echo "[1/6] Downloads 폴더 준비"
mkdir -p ~/Downloads
chmod 755 ~/Downloads

echo "[2/6] 패키지를 ~/Downloads에 다운로드"
curl -L -o ~/Downloads/nomachine_9.5.7_2_amd64.deb \
    https://web9001.nomachine.com/download/9.5/Linux/nomachine_9.5.7_2_amd64.deb
chmod 644 ~/Downloads/nomachine_9.5.7_2_amd64.deb

echo "[3/6] NoMachine 설치"
sudo apt install -y ~/Downloads/nomachine_9.5.7_2_amd64.deb

echo "[4/6] NoMachine 서비스 상태 확인"
sudo systemctl status nxserver --no-pager

echo "[5/6] 서버 IP 확인"
hostname -I

echo "[6/6] NVIDIA GPU 확인"
nvidia-smi || true

echo "접속 방법:"
echo "  nx://<서버IP>:4000"
echo "예시:"
echo "  nx://192.168.0.10:4000"
echo "NoMachine 9.5.7 설치 완료"
