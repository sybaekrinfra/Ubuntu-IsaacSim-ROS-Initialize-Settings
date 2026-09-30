#!/bin/bash
set -e

# 이미 세팅된 PC(NoMachine/XRDP로 쓰던 PC, 순정 xfce 세션으로 로그인하던 PC 등)를
# 현재 저장소 기준 설정(LightDM 자동 로그인 + Xubuntu 세션 + Sunshine + 패널/배경화면)으로
# 맞춰주는 스크립트. 여러 번 실행해도 안전하다.
# NoMachine/XRDP는 설치되어 있어도 건드리지 않는다.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

if [ "$(id -u)" -eq 0 ]; then
    echo "오류: root가 아닌 일반 사용자로 실행하세요 (필요한 곳에서 sudo를 사용합니다)." >&2
    exit 1
fi

echo "기존 시스템 설정 갱신 시작"
sudo -v

echo "[1/4] Xfce Desktop / LightDM 자동 로그인(Xubuntu 세션) 설정"
bash install/install_desktop.sh

echo "[2/4] Sunshine 확인"
if dpkg -s sunshine >/dev/null 2>&1; then
    echo "  - Sunshine이 이미 설치되어 있어 기존 설정을 그대로 둡니다."
else
    echo "  - Sunshine이 없어 설치합니다."
    bash install/install_sunshine.sh
fi

echo "[3/4] 바탕화면 바로가기 복사 및 패널/배경화면 재구성"
rm -f "$HOME/.config/xfce4/panel/.xubuntu-layout-v5"
# 배경화면은 현재 세션에 존재하는 모니터에만 적용되므로, 로컬 Xubuntu 세션이 아닐 때
# (XRDP/NoMachine 가상 세션, SSH 등)는 바로 적용하지 않고 다음 Xubuntu 로그인 때 적용한다.
if [ "${DESKTOP_SESSION:-}" = "xubuntu" ] && [ -z "${XRDP_SESSION:-}" ]; then
    bash install/copy_files.sh
else
    env -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS bash install/copy_files.sh
fi

echo "[4/4] 완료"
echo "재부팅하면 LightDM이 ${USER} 계정으로 Xubuntu 세션에 자동 로그인하고,"
echo "패널/배경화면 설정과 Sunshine이 적용됩니다."
echo "NoMachine/XRDP는 변경하지 않았습니다."

if [ -t 0 ]; then
    read -r -p "지금 재부팅할까요? [y/N] " answer
    case "$answer" in
        y|Y|yes|YES)
            sudo reboot
            ;;
    esac
fi
echo "나중에 'sudo reboot'로 재부팅하세요."
