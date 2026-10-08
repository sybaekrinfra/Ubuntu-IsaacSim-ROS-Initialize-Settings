#!/bin/bash
set -e

# 워크스테이션 모니터링: 소프트웨어 기준 정보 + 원격 GUI/드라이버 위험 수집기 (읽기 전용)
# - 10분마다 Node Exporter textfile(system_info.prom)로 아래 값을 기록합니다.
#     소프트웨어 버전 (krinfra_software_info{component,version})
#       os, kernel, nvidia_driver, cuda_driver_api(nvidia-smi가 표시하는 "CUDA Version" = 드라이버가 지원하는 최대 CUDA API),
#       nvidia_kernel_module(open|proprietary — Blackwell/RTX 50 은 open 필수),
#       cuda_toolkit(실제 설치된 nvcc/Toolkit, 없으면 none), isaacsim, isaaclab, ros2, sunshine, docker,
#       nvidia_container_toolkit, dcgm_exporter_image
#     위험 지표
#       krinfra_nvidia_smi_ok                   nvidia-smi 정상 동작 (드라이버/NVML 불일치 감지)
#       krinfra_nvidia_module_for_latest_kernel 설치된 최신 커널용 NVIDIA 모듈 존재 (커널 업데이트 후 재부팅 시 드라이버 미로드 위험)
#       krinfra_kernel_reboot_pending           최신 설치 커널과 실행 중 커널이 다름 (재부팅 대기)
#       krinfra_gui_session_active              Sunshine 사용자의 X11 그래픽 세션 존재 (LightDM 자동 로그인/Xfce 세션)
#       krinfra_gpu_display_active              GPU에 디스플레이(모니터/더미 플러그)가 활성 상태
# - 개발자의 프로젝트, 소스 코드, 데이터는 읽지 않습니다.
#   Isaac Sim/Isaac Lab은 설치 폴더의 VERSION 파일만 읽습니다. 값이 없으면 none, 읽을 수 없으면 unknown으로 기록합니다.
# - 드라이버, 커널, 패키지를 변경하지 않습니다. 여러 번 실행해도 안전합니다.
#
# 환경 변수
#   TARGET_USER   Isaac Sim, Isaac Lab, Sunshine을 쓰는 계정 (기본: 현재 사용자)
#   ISAACSIM_DIR  기본 ~TARGET_USER/isaacsim (install/install_isaacsim.sh 기본 경로)
#   ISAACLAB_DIR  기본 ~TARGET_USER/IsaacLab (install/install_isaaclab.sh 기본 경로)

TARGET_USER="${TARGET_USER:-${USER}}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
ISAACSIM_DIR="${ISAACSIM_DIR:-${TARGET_HOME}/isaacsim}"
ISAACLAB_DIR="${ISAACLAB_DIR:-${TARGET_HOME}/IsaacLab}"
LIB_DIR="/usr/local/lib/krinfra"
SCRIPT="${LIB_DIR}/system_info_metrics.sh"
UNIT="krinfra-system-info"

echo "시스템 기준 정보 수집기 설치 시작"

echo "[1/3] Node Exporter textfile 디렉터리 확인"
if systemctl is-active --quiet prometheus-node-exporter.service; then
    TEXTFILE_DIR="/var/lib/prometheus/node-exporter"
elif systemctl is-active --quiet node_exporter.service; then
    TEXTFILE_DIR="/var/lib/node_exporter/textfile"
else
    echo "오류: Node Exporter가 동작하지 않습니다. install/install_node_exporter.sh를 먼저 실행하세요." >&2
    exit 1
fi
echo "  - ${TEXTFILE_DIR} (대상 사용자: ${TARGET_USER}, Isaac Sim: ${ISAACSIM_DIR}, Isaac Lab: ${ISAACLAB_DIR})"

echo "[2/3] 수집 스크립트와 systemd timer 배포"
sudo install -d -m 755 "${LIB_DIR}"
tmp="$(mktemp)"
cat > "${tmp}" <<EOF
#!/bin/bash
# krinfra 모니터링: 시스템 기준 정보 → Node Exporter textfile (install/install_system_info_metrics.sh가 생성)
set -u
OUT=${TEXTFILE_DIR}/system_info.prom
TARGET_USER=${TARGET_USER}
ISAACSIM_DIR=${ISAACSIM_DIR}
ISAACLAB_DIR=${ISAACLAB_DIR}
EOF
cat >> "${tmp}" <<'EOF'

esc() { printf '%s' "$1" | tr -d '\n\r"\\' | cut -c1-80; }
info_lines=""
add_info() {   # $1=component $2=version
    local v; v="$(esc "${2:-unknown}")"; [ -z "$v" ] && v="unknown"
    info_lines+="krinfra_software_info{component=\"$1\",version=\"$v\"} 1"$'\n'
}
read_version_file() {   # $1=dir → VERSION 첫 줄, 폴더 없으면 none
    if [ ! -d "$1" ]; then echo none; elif [ -r "$1/VERSION" ]; then head -1 "$1/VERSION"; else echo unknown; fi
}

. /etc/os-release
add_info os "${PRETTY_NAME:-unknown}"
add_info kernel "$(uname -r)"

smi_ok=0
if smi_out="$(nvidia-smi 2>/dev/null)"; then
    smi_ok=1
    add_info nvidia_driver "$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)"
    add_info cuda_driver_api "$(grep -o 'CUDA Version: [0-9.]*' <<<"$smi_out" | awk '{print $3}')"
    display_active="$(nvidia-smi --query-gpu=display_active --format=csv,noheader 2>/dev/null | head -1)"
else
    add_info nvidia_driver "error"
    display_active=""
fi

# 커널 모듈 종류: Blackwell(RTX 50 시리즈, RTX 5070 Ti 등)은 오픈 커널 모듈(nvidia-driver-XXX-open)만 지원
if [ -r /proc/driver/nvidia/version ]; then
    if grep -qi 'open kernel module' /proc/driver/nvidia/version; then add_info nvidia_kernel_module open; else add_info nvidia_kernel_module proprietary; fi
else
    add_info nvidia_kernel_module none
fi

if command -v nvcc >/dev/null 2>&1; then
    add_info cuda_toolkit "$(nvcc --version | sed -n 's/.*release \([0-9.]*\).*/\1/p')"
elif [ -r /usr/local/cuda/version.json ]; then
    add_info cuda_toolkit "$(sed -n 's/.*"cuda" *: *{[^}]*"version" *: *"\([^"]*\)".*/\1/p' /usr/local/cuda/version.json | head -1)"
else
    add_info cuda_toolkit none
fi

add_info isaacsim "$(read_version_file "$ISAACSIM_DIR")"
add_info isaaclab "$(read_version_file "$ISAACLAB_DIR")"
ros="$(ls /opt/ros 2>/dev/null | paste -sd, -)"; add_info ros2 "${ros:-none}"
add_info sunshine "$(dpkg-query -W -f='${Version}' sunshine 2>/dev/null || echo none)"
add_info docker "$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo none)"
add_info nvidia_container_toolkit "$(dpkg-query -W -f='${Version}' nvidia-container-toolkit 2>/dev/null || echo none)"
if img="$(docker inspect -f '{{.Config.Image}}' krinfra-dcgm-exporter 2>/dev/null)"; then
    add_info dcgm_exporter_image "${img##*:}"
else
    add_info dcgm_exporter_image none
fi

# 설치된 최신 커널용 NVIDIA 모듈 존재 여부 (재부팅 후 드라이버 로드 실패 위험)
latest_kernel="$(ls /lib/modules 2>/dev/null | sort -V | tail -1)"
mod_ok=0; modinfo -k "$latest_kernel" nvidia >/dev/null 2>&1 && mod_ok=1
reboot_pending=0; [ "$latest_kernel" != "$(uname -r)" ] && reboot_pending=1

# 대상 사용자의 활성 X11 그래픽 세션 (LightDM 자동 로그인 → Xubuntu 세션)
gui=0
for sid in $(loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$TARGET_USER" '$3==u {print $1}'); do
    t="$(loginctl show-session "$sid" -p Type --value 2>/dev/null)"
    a="$(loginctl show-session "$sid" -p Active --value 2>/dev/null)"
    if [ "$t" = "x11" ] && [ "$a" = "yes" ]; then gui=1; fi
done

disp_line=""
case "$display_active" in
    Enabled) disp_line="krinfra_gpu_display_active 1" ;;
    Disabled) disp_line="krinfra_gpu_display_active 0" ;;
esac

tmp=$(mktemp "$OUT.XXXXXX") || exit 1
cat > "$tmp" <<PROM
# HELP krinfra_software_info 워크스테이션 소프트웨어 버전 (값은 항상 1, version 레이블 참조)
# TYPE krinfra_software_info gauge
${info_lines}# HELP krinfra_nvidia_smi_ok nvidia-smi 정상 동작 여부
# TYPE krinfra_nvidia_smi_ok gauge
krinfra_nvidia_smi_ok $smi_ok
# HELP krinfra_nvidia_module_for_latest_kernel 설치된 최신 커널($latest_kernel)용 NVIDIA 커널 모듈 존재 여부
# TYPE krinfra_nvidia_module_for_latest_kernel gauge
krinfra_nvidia_module_for_latest_kernel{kernel="$latest_kernel"} $mod_ok
# HELP krinfra_kernel_reboot_pending 최신 설치 커널과 실행 중 커널이 다름(재부팅 대기)
# TYPE krinfra_kernel_reboot_pending gauge
krinfra_kernel_reboot_pending $reboot_pending
# HELP krinfra_gui_session_active 대상 사용자의 활성 X11 그래픽 세션 존재 여부
# TYPE krinfra_gui_session_active gauge
krinfra_gui_session_active{user="$TARGET_USER"} $gui
# HELP krinfra_gpu_display_active GPU 디스플레이 활성 여부 (nvidia-smi display_active, 미지원 시 미기록)
# TYPE krinfra_gpu_display_active gauge
${disp_line}
# HELP krinfra_system_info_last_run_timestamp_seconds 수집 스크립트 마지막 실행 시각
# TYPE krinfra_system_info_last_run_timestamp_seconds gauge
krinfra_system_info_last_run_timestamp_seconds $(date +%s)
PROM
chmod 0644 "$tmp" && mv -f "$tmp" "$OUT"
EOF
sudo install -m 755 "${tmp}" "${SCRIPT}"
rm -f "${tmp}"

sudo tee "/etc/systemd/system/${UNIT}.service" >/dev/null <<EOF
[Unit]
Description=krinfra: system/software baseline -> node_exporter textfile (read-only)

[Service]
Type=oneshot
ExecStart=${SCRIPT}
# root: docker/loginctl 조회에 필요. 쓰기는 textfile 디렉터리로 제한, 홈은 읽기 전용(VERSION 파일만 읽음).
ProtectSystem=strict
ReadWritePaths=${TEXTFILE_DIR}
ProtectHome=read-only
PrivateTmp=yes
NoNewPrivileges=yes
Nice=10
EOF

sudo tee "/etc/systemd/system/${UNIT}.timer" >/dev/null <<EOF
[Unit]
Description=krinfra: system/software baseline collection every 10min

[Timer]
OnBootSec=1min
OnUnitActiveSec=10min
AccuracySec=30s

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now "${UNIT}.timer"
sudo systemctl start "${UNIT}.service"

echo "[3/3] 결과 확인"
grep -v '^#' "${TEXTFILE_DIR}/system_info.prom" | sed 's/^/  /'
echo "시스템 기준 정보 수집기 설치 완료"
