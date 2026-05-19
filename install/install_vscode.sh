#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "VSCode 설치 시작"

echo ""
echo "[1/5] apt 업데이트"
sudo apt update

echo ""
echo "[2/5] 필수 패키지 설치"
sudo apt install -y wget gpg apt-transport-https

echo ""
echo "[3/5] Microsoft GPG 키 추가"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null

echo ""
echo "[4/5] VSCode 저장소 추가"
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

echo ""
echo "[5/5] VSCode 설치"
sudo apt update
sudo apt install -y code

banner "VSCode 설치 완료"
code --version
