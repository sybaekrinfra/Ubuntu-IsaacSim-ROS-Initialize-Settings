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
    elementary-xfce-icon-theme \
    xubuntu-default-settings

echo "[2/4] LightDM을 기본 디스플레이 매니저로 지정하고 설치"
echo "lightdm shared/default-x-display-manager select lightdm" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install -y lightdm

echo "[3/4] LightDM 자동 로그인 설정 (${USER} / Xfce)"

XFCE_SESSION_FILE="/usr/share/xsessions/xfce.desktop"
if [ ! -f "${XFCE_SESSION_FILE}" ]; then
    echo "오류: ${XFCE_SESSION_FILE}이 없습니다. Xfce 세션 설치를 확인한 뒤 다시 실행하세요." >&2
    exit 1
fi

AUTOLOGIN_FILE="/etc/lightdm/lightdm.conf.d/50-autologin.conf"
DESIRED_AUTOLOGIN="[Seat:*]
autologin-user=${USER}
autologin-user-timeout=0
user-session=xfce"

sudo mkdir -p /etc/lightdm/lightdm.conf.d

# 다른 lightdm 설정 파일에 이미 autologin-user가 지정돼 있으면 충돌을 피하기 위해 중단한다.
CONFLICTS="$(sudo grep -l '^autologin-user=' /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.d/*.conf 2>/dev/null | grep -vx "${AUTOLOGIN_FILE}" || true)"
if [ -n "${CONFLICTS}" ]; then
    echo "오류: 다음 파일에 이미 autologin-user 설정이 있어 자동으로 덮어쓰지 않습니다:" >&2
    for f in ${CONFLICTS}; do
        echo "  - ${f}:" >&2
        sudo grep '^autologin-user=' "${f}" | sed 's/^/      /' >&2
    done
    echo "위 설정을 직접 확인하고 정리한 뒤 다시 실행하세요." >&2
    exit 1
fi

if [ -f "${AUTOLOGIN_FILE}" ] && [ "$(sudo cat "${AUTOLOGIN_FILE}")" = "${DESIRED_AUTOLOGIN}" ]; then
    echo "  - ${AUTOLOGIN_FILE}이 이미 원하는 내용으로 설정되어 있어 건너뜁니다."
else
    if [ -f "${AUTOLOGIN_FILE}" ]; then
        BACKUP_FILE="${AUTOLOGIN_FILE}.bak.$(date +%Y%m%d%H%M%S)"
        echo "  - 기존 ${AUTOLOGIN_FILE}을 ${BACKUP_FILE}로 백업합니다."
        sudo cp -a "${AUTOLOGIN_FILE}" "${BACKUP_FILE}"
    fi
    printf '%s\n' "${DESIRED_AUTOLOGIN}" | sudo tee "${AUTOLOGIN_FILE}" > /dev/null
fi

echo "[4/4] 설정 확인"
cat "${AUTOLOGIN_FILE}"

echo "Xfce Desktop / LightDM 자동 로그인 설정 완료"
echo "재부팅하면 ${USER} 계정으로 자동 로그인되어 Xfce 세션이 시작되고,"
echo "그 세션 안에서 Sunshine 사용자 서비스도 함께 시작됩니다."
