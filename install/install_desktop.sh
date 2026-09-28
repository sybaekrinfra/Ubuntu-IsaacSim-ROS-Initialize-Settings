#!/bin/bash
set -e

echo "Xfce Desktop 및 LightDM 자동 로그인 설정 시작"

echo "[1/4] Xfce Desktop 관련 패키지 설치"
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    xfce4 \
    xfce4-terminal \
    xfce4-whiskermenu-plugin \
    xfce4-pulseaudio-plugin \
    xfce4-power-manager \
    xfce4-notifyd \
    pavucontrol \
    fonts-noto-core \
    greybird-gtk-theme \
    elementary-xfce-icon-theme

echo "[2/4] LightDM을 기본 디스플레이 매니저로 지정하고 설치"
echo "lightdm shared/default-x-display-manager select lightdm" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install -y lightdm

echo "[3/4] LightDM 자동 로그인 설정 (${USER} / Xfce)"
sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=${USER}
autologin-user-timeout=0
user-session=xfce
EOF

echo "[4/4] 설정 확인"
cat /etc/lightdm/lightdm.conf.d/50-autologin.conf

echo "Xfce Desktop / LightDM 자동 로그인 설정 완료"
echo "재부팅하면 ${USER} 계정으로 자동 로그인되어 Xfce 세션이 시작되고,"
echo "그 세션 안에서 Sunshine 사용자 서비스도 함께 시작됩니다."
