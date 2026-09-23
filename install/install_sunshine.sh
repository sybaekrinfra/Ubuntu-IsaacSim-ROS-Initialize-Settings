#!/bin/bash
set -e

echo "Sunshine 설치 시작"

echo "[1/5] Cloudsmith 저장소 구성"
curl -1sLf 'https://dl.cloudsmith.io/public/lizardbyte/stable/cfg/setup/bash.deb.sh' | sudo -E bash

echo "[2/5] Sunshine 설치"
sudo apt update
sudo apt install -y sunshine

echo "[3/5] 입력 장치 사용을 위해 현재 사용자를 input 그룹에 추가"
sudo usermod -aG input "${USER}"

echo "[4/5] sunshine.conf 기본값 설정"
CONFIG_DIR="$HOME/.config/sunshine"
CONFIG_FILE="${CONFIG_DIR}/sunshine.conf"
mkdir -p "${CONFIG_DIR}"
touch "${CONFIG_FILE}"

set_conf() {
    local key="$1" value="$2"
    if grep -q "^${key} *=" "${CONFIG_FILE}" 2>/dev/null; then
        sed -i "s|^${key} *=.*|${key} = ${value}|" "${CONFIG_FILE}"
    else
        printf '%s = %s\n' "${key}" "${value}" >> "${CONFIG_FILE}"
    fi
}

set_conf "capture" "x11"

if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    echo "  - NVIDIA 드라이버 감지: encoder = nvenc"
    set_conf "encoder" "nvenc"
else
    echo "  - NVIDIA 드라이버 미감지: encoder는 기본값(자동 선택)을 사용합니다."
fi

LOCAL_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')"
if [ -z "${LOCAL_IP}" ]; then
    LOCAL_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

if [ -n "${LOCAL_IP}" ]; then
    echo "  - 감지된 IP: ${LOCAL_IP} -> csrf_allowed_origins 설정"
    set_conf "csrf_allowed_origins" "https://${LOCAL_IP}:47990"
else
    echo "  - IP를 감지하지 못해 csrf_allowed_origins 설정을 건너뜁니다."
fi

echo "[5/5] Sunshine 사용자 서비스 활성화"
systemctl --user --now enable app-dev.lizardbyte.app.Sunshine
systemctl --user restart app-dev.lizardbyte.app.Sunshine

echo "Sunshine 설치 완료"
echo "input 그룹 적용을 위해 로그아웃 후 다시 로그인하세요."
if [ -n "${LOCAL_IP}" ]; then
    echo "웹 UI: https://${LOCAL_IP}:47990"
else
    echo "웹 UI: https://localhost:47990"
fi
