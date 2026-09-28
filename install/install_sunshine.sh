#!/bin/bash
set -e

echo "Sunshine 설치 시작"

echo "[1/9] Cloudsmith 저장소 구성"
curl -1sLf 'https://dl.cloudsmith.io/public/lizardbyte/stable/cfg/setup/bash.deb.sh' | sudo -E bash

echo "[2/9] Sunshine 설치"
sudo apt update
sudo apt install -y sunshine

echo "[3/9] 입력 장치 사용을 위해 현재 사용자를 input 그룹에 추가"
sudo usermod -aG input "${USER}"

echo "[4/9] sunshine.conf 기본값 설정"
CONFIG_DIR="$HOME/.config/sunshine"
CONFIG_FILE="${CONFIG_DIR}/sunshine.conf"
mkdir -p "${CONFIG_DIR}"
touch "${CONFIG_FILE}"

set_conf() {
    local key="$1" value="$2" escaped
    escaped="$(printf '%s' "${value}" | sed -e 's/[\&|]/\\&/g')"
    if grep -q "^${key} *=" "${CONFIG_FILE}" 2>/dev/null; then
        sed -i "s|^${key} *=.*|${key} = ${escaped}|" "${CONFIG_FILE}"
    else
        printf '%s = %s\n' "${key}" "${value}" >> "${CONFIG_FILE}"
    fi
}

LOCAL_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')"
if [ -z "${LOCAL_IP}" ]; then
    LOCAL_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

set_conf "capture" "x11"

if [ -n "${LOCAL_IP}" ]; then
    LAST_OCTET="${LOCAL_IP##*.}"
    SUNSHINE_NAME="${USER}_${LAST_OCTET}"
else
    SUNSHINE_NAME="${USER}"
fi
echo "  - sunshine_name = ${SUNSHINE_NAME}"
set_conf "sunshine_name" "${SUNSHINE_NAME}"

if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    echo "  - NVIDIA 드라이버 감지: encoder = nvenc"
    set_conf "encoder" "nvenc"
else
    echo "  - NVIDIA 드라이버 미감지: encoder는 기본값(자동 선택)을 사용합니다."
fi

if [ -n "${LOCAL_IP}" ]; then
    echo "  - 감지된 IP: ${LOCAL_IP} -> csrf_allowed_origins 설정"
    set_conf "csrf_allowed_origins" "https://${LOCAL_IP}:47990"
else
    echo "  - IP를 감지하지 못해 csrf_allowed_origins 설정을 건너뜁니다."
fi

echo "[5/9] 접속 시 마우스 가속 보정 훅 등록"
HOOK_DIR="$HOME/.local/bin"
HOOK_FILE="${HOOK_DIR}/sunshine-disable-mouse-accel.sh"
mkdir -p "${HOOK_DIR}"
cat > "${HOOK_FILE}" <<'EOF'
#!/bin/bash
# Sunshine 세션 시작 시 global_prep_cmd로 백그라운드 실행됨.
# Sunshine 가상 마우스는 X server 입장에서 일반 마우스와 동일하게 취급되어
# libinput의 기본 pointer acceleration이 그대로 적용되므로, 감도가 물리 마우스보다
# 높게 느껴지는 것을 막기 위해 해당 장치의 가속을 끈다.
for _ in $(seq 1 30); do
    while IFS= read -r name; do
        [ -z "${name}" ] && continue
        if xinput list-props "${name}" 2>/dev/null | grep -q "libinput Accel Profile Enabled"; then
            xinput set-prop "${name}" "libinput Accel Profile Enabled" 0, 1 2>/dev/null
            xinput set-prop "${name}" "libinput Accel Speed" -1 2>/dev/null
        fi
    done < <(xinput list --name-only 2>/dev/null | grep -i sunshine)
    sleep 0.5
done
EOF
chmod +x "${HOOK_FILE}"

set_conf "global_prep_cmd" '[{"do":"setsid -f $(HOME)/.local/bin/sunshine-disable-mouse-accel.sh >/tmp/sunshine-mouse-accel.log 2>&1","undo":""}]'

echo "[6/9] apps.json에서 Desktop 항목만 남기기"
APPS_FILE="${CONFIG_DIR}/apps.json"
cat > "${APPS_FILE}" <<'EOF'
{
    "env": {
        "PATH": "$(PATH):$(HOME)/.local/bin"
    },
    "apps": [
        {
            "name": "Desktop",
            "image-path": "desktop.png"
        }
    ]
}
EOF

echo "[7/9] 웹 UI 로그인 자격증명 설정"
WEBUI_PASSWORD="1"
sunshine --creds "${USER}" "${WEBUI_PASSWORD}"
echo "  - 웹 UI 아이디: ${USER} / 비밀번호: ${WEBUI_PASSWORD} (매우 단순한 비밀번호입니다. 필요하면 웹 UI에서 나중에 바꾸세요.)"

echo "[8/9] 중복 override 정리 및 XFCE autostart로 자동 시작 설정"
SUNSHINE_UNIT="app-dev.lizardbyte.app.Sunshine.service"
OVERRIDE_DIR="$HOME/.config/systemd/user/${SUNSHINE_UNIT}.d"
OVERRIDE_FILE="${OVERRIDE_DIR}/override.conf"

# Sunshine 원본 unit에 이미 ExecStartPre=/bin/sleep 5 / Restart=on-failure / RestartSec=5가
# 들어있어서, 예전 버전의 이 스크립트가 만들어 둔 동일 내용의 override는 그냥 중복이다. 남아있다면 정리한다.
REDUNDANT_OVERRIDE="[Service]
ExecStartPre=/bin/sleep 5
Restart=on-failure
RestartSec=5"

if [ -f "${OVERRIDE_FILE}" ]; then
    if [ "$(cat "${OVERRIDE_FILE}")" = "${REDUNDANT_OVERRIDE}" ]; then
        echo "  - 원본 unit과 중복되는 override(${OVERRIDE_FILE})를 제거합니다."
        rm -f "${OVERRIDE_FILE}"
        rmdir --ignore-fail-on-non-empty "${OVERRIDE_DIR}" 2>/dev/null || true
    else
        echo "  - ${OVERRIDE_FILE}에 다른 설정이 있어 건드리지 않고 그대로 둡니다:"
        sed 's/^/      /' "${OVERRIDE_FILE}"
    fi
fi
systemctl --user daemon-reload

# XFCE는 로그인해도 graphical-session.target을 활성화하지 않는 경우가 있어
# WantedBy=graphical-session.target만으로는 자동 시작이 보장되지 않는다.
# XFCE 자체 autostart로 로그인 직후 명시적으로 서비스를 시작시킨다.
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="${AUTOSTART_DIR}/sunshine-systemd.desktop"
mkdir -p "${AUTOSTART_DIR}"
DESIRED_AUTOSTART="[Desktop Entry]
Type=Application
Name=Sunshine
Comment=Start Sunshine systemd user service after XFCE login
Exec=systemctl --user start ${SUNSHINE_UNIT}
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true"

if [ -f "${AUTOSTART_FILE}" ] && [ "$(cat "${AUTOSTART_FILE}")" = "${DESIRED_AUTOSTART}" ]; then
    echo "  - ${AUTOSTART_FILE}이 이미 최신 상태입니다."
else
    printf '%s\n' "${DESIRED_AUTOSTART}" > "${AUTOSTART_FILE}"
    echo "  - ${AUTOSTART_FILE} 생성/갱신 완료."
fi

echo "[9/9] Sunshine 사용자 서비스 활성화"
systemctl --user --now enable "${SUNSHINE_UNIT}"
systemctl --user restart "${SUNSHINE_UNIT}"

echo "Sunshine 설치 완료"
echo "input 그룹 적용을 위해 로그아웃 후 다시 로그인하세요."
echo "웹 UI 로그인 아이디/비밀번호: ${USER} / ${WEBUI_PASSWORD}"
if [ -n "${LOCAL_IP}" ]; then
    echo "웹 UI: https://${LOCAL_IP}:47990"
else
    echo "웹 UI: https://localhost:47990"
fi
echo ""
echo "재부팅 후 확인 명령:"
echo "  loginctl list-sessions"
echo "  systemctl --user status ${SUNSHINE_UNIT} --no-pager"
echo "  journalctl --user -u ${SUNSHINE_UNIT} -b --no-pager | tail -80"
