#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "VSCode install start"

echo ""
echo "[1/5] Update apt"
sudo apt update

echo ""
echo "[2/5] Install prerequisites"
sudo apt install -y wget gpg apt-transport-https

echo ""
echo "[3/5] Add Microsoft GPG key"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null

echo ""
echo "[4/5] Add VSCode repository"
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

echo ""
echo "[5/5] Install VSCode"
sudo apt update
sudo apt install -y code

banner "VSCode install complete"
code --version
