#!/bin/bash
set -e

# 워크스테이션 모니터링 3/3: Sunshine 상태 수집기 (읽기 전용)
# - 30초마다 Sunshine 상태를 Node Exporter textfile(sunshine.prom)로 기록합니다. 기록 항목은 다음과 같습니다.
#     프로세스 실행 여부, 47989/tcp LISTEN 여부, 사용자 서비스(app-dev.lizardbyte.app.Sunshine) active 여부
# - Sunshine 설정과 서비스는 변경하거나 재시작하지 않습니다. Moonlight 세션 연결 여부는 수집하지 않습니다.
# - 메트릭 이름은 중앙 서버(krinfra) Ansible role sunshine_metrics와 같습니다.
#
# 환경 변수
#   SUNSHINE_USER      Sunshine 사용자 서비스를 실행하는 계정 (기본: 현재 사용자)
#   SUNSHINE_EXPECTED  1이면 Sunshine 미실행 시 경보 대상 (기본: sunshine 패키지가 설치되어 있으면 1)

SUNSHINE_USER="${SUNSHINE_USER:-${USER}}"
SUNSHINE_PORT=47989
LIB_DIR="/usr/local/lib/krinfra"
SCRIPT="${LIB_DIR}/sunshine_metrics.sh"
UNIT="krinfra-sunshine-metrics"

if [ -z "${SUNSHINE_EXPECTED:-}" ]; then
    if dpkg -s sunshine >/dev/null 2>&1; then SUNSHINE_EXPECTED=1; else SUNSHINE_EXPECTED=0; fi
fi

echo "Sunshine 상태 수집기 설치 시작"

echo "[1/3] Node Exporter textfile 디렉터리 확인"
if systemctl is-active --quiet prometheus-node-exporter.service; then
    TEXTFILE_DIR="/var/lib/prometheus/node-exporter"
elif systemctl is-active --quiet node_exporter.service; then
    TEXTFILE_DIR="/var/lib/node_exporter/textfile"
else
    echo "오류: Node Exporter가 동작하지 않습니다. install/install_node_exporter.sh를 먼저 실행하세요." >&2
    exit 1
fi
[ -d "${TEXTFILE_DIR}" ] || { echo "오류: ${TEXTFILE_DIR}이(가) 없습니다." >&2; exit 1; }
echo "  - ${TEXTFILE_DIR} (sunshine 사용자: ${SUNSHINE_USER}, 경보 대상: ${SUNSHINE_EXPECTED})"

echo "[2/3] 수집 스크립트와 systemd timer 배포"
sudo install -d -m 755 "${LIB_DIR}"
tmp="$(mktemp)"
cat > "${tmp}" <<EOF
#!/bin/bash
# krinfra 모니터링: Sunshine 상태 → Node Exporter textfile (install/install_sunshine_metrics.sh가 생성)
# 주의: 이 값은 Sunshine 프로세스/포트 상태이며 Moonlight 세션 연결 여부가 아닙니다.
set -u
OUT=${TEXTFILE_DIR}/sunshine.prom
PORT=${SUNSHINE_PORT}
EXPECTED=${SUNSHINE_EXPECTED}
SUNSHINE_USER=${SUNSHINE_USER}
EOF
cat >> "${tmp}" <<'EOF'

running=0; start=0
pid=$(pgrep -o -x sunshine 2>/dev/null || true)
[ -z "$pid" ] && pid=$(pgrep -o -f '(^|/)sunshine(\.AppImage)?( |$)' 2>/dev/null || true)
if [ -n "$pid" ]; then
  running=1
  et=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
  [ -n "$et" ] && start=$(( $(date +%s) - et ))
fi

listening=0
ss -Htln "sport = :$PORT" 2>/dev/null | grep -q . && listening=1

unit_lines=""
st=$(systemctl is-active sunshine.service 2>/dev/null || true)
[ "$st" = active ] && v=1 || v=0
unit_lines+="sunshine_systemd_unit_active{scope=\"system\",unit=\"sunshine.service\"} $v"$'\n'
if [ -n "$SUNSHINE_USER" ]; then
  for u in app-dev.lizardbyte.app.Sunshine.service sunshine.service; do
    st=$(systemctl --user -M "${SUNSHINE_USER}@" is-active "$u" 2>/dev/null || true)
    [ "$st" = active ] && v=1 || v=0
    unit_lines+="sunshine_systemd_unit_active{scope=\"user\",unit=\"$u\"} $v"$'\n'
  done
fi

tmp=$(mktemp "$OUT.XXXXXX") || exit 1
cat > "$tmp" <<PROM
# HELP sunshine_process_running Sunshine 프로세스 실행 여부 (1=실행 중). Moonlight 세션 여부 아님.
# TYPE sunshine_process_running gauge
sunshine_process_running $running
# HELP sunshine_process_start_time_seconds Sunshine 프로세스 시작 시각 (미실행 시 0)
# TYPE sunshine_process_start_time_seconds gauge
sunshine_process_start_time_seconds $start
# HELP sunshine_port_listening 워크스테이션 내부에서 Sunshine nvhttp 포트 LISTEN 여부
# TYPE sunshine_port_listening gauge
sunshine_port_listening{port="$PORT"} $listening
# HELP sunshine_expected 이 호스트에서 Sunshine 이 실행되어야 하는지 (경보 판단용)
# TYPE sunshine_expected gauge
sunshine_expected $EXPECTED
# HELP sunshine_systemd_unit_active Sunshine systemd 유닛 active 여부
# TYPE sunshine_systemd_unit_active gauge
${unit_lines}# HELP sunshine_metrics_last_run_timestamp_seconds 수집 스크립트 마지막 실행 시각
# TYPE sunshine_metrics_last_run_timestamp_seconds gauge
sunshine_metrics_last_run_timestamp_seconds $(date +%s)
PROM
chmod 0644 "$tmp" && mv -f "$tmp" "$OUT"
EOF
sudo install -m 755 "${tmp}" "${SCRIPT}"
rm -f "${tmp}"

sudo tee "/etc/systemd/system/${UNIT}.service" >/dev/null <<EOF
[Unit]
Description=krinfra: Sunshine status -> node_exporter textfile (read-only)

[Service]
Type=oneshot
ExecStart=${SCRIPT}
# root: 사용자 systemd 유닛 조회(systemctl --user -M)에 필요. 쓰기는 textfile 디렉터리로 제한.
ProtectSystem=strict
ReadWritePaths=${TEXTFILE_DIR}
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
Nice=10
EOF

sudo tee "/etc/systemd/system/${UNIT}.timer" >/dev/null <<EOF
[Unit]
Description=krinfra: Sunshine status collection every 30s

[Timer]
OnBootSec=30s
OnUnitActiveSec=30s
AccuracySec=5s

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now "${UNIT}.timer"
sudo systemctl start "${UNIT}.service"

echo "[3/3] 결과 확인"
grep -v '^#' "${TEXTFILE_DIR}/sunshine.prom" | sed 's/^/  /'
echo "Sunshine 상태 수집기 설치 완료"
