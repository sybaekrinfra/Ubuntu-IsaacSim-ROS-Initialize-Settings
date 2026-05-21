#!/bin/bash
set -e

echo "Google Chrome 설치 시작"
echo "[1/5] Downloads 폴더 준비"
mkdir -p ~/Downloads
chmod 755 ~/Downloads

echo "[2/5] 패키지를 ~/Downloads에 다운로드"
curl -L -o ~/Downloads/google-chrome-stable_current_amd64.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
chmod 644 ~/Downloads/google-chrome-stable_current_amd64.deb

echo "[3/5] Google Chrome 설치"
sudo apt install -y ~/Downloads/google-chrome-stable_current_amd64.deb

echo "[4/5] 설치 확인"
google-chrome --version

echo "[5/5] 기본 브라우저 안내"
echo "필요하면 Settings > Default Applications에서 Chrome을 선택하세요."
echo "실행 명령어:"
echo "  google-chrome"
echo "Google Chrome 설치 완료"
