#!/bin/bash
set -e

echo "Google Chrome 설치 시작"
echo "[1/6] Downloads 폴더로 이동"
cd ~/Downloads

echo "[2/6] Google Chrome 다운로드"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

echo "[3/6] Google Chrome 설치"
sudo apt install -y ./google-chrome-stable_current_amd64.deb

echo "[4/6] 설치 확인"
google-chrome --version

echo "[5/6] 기본 브라우저 안내"
echo "필요하면 Settings > Default Applications에서 Chrome을 선택하세요."

echo "[6/6] 마무리"
echo "실행 명령어:"
echo "  google-chrome"
echo "Google Chrome 설치 완료"
