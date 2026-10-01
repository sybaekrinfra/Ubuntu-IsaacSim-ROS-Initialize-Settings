#!/bin/bash
set -e

# Isaac Sim / Omniverse Kit은 실행할 때마다 ~/.nvidia-omniverse/logs 아래에
# 새 로그 파일을 만들고 지우지 않아서 시간이 지나면 폴더가 계속 커집니다.
# systemd 사용자 타이머로 오래된 로그를 주기적으로 정리합니다.
#   - LOG_MAX_AGE_DAYS(기본 7)일보다 오래된 로그 파일 삭제
#   - 그래도 LOG_MAX_SIZE_MB(기본 2048)MB를 넘으면 오래된 파일부터 삭제
#     (최근 60분 안에 수정된 파일은 실행 중인 세션의 로그일 수 있어 건너뜀)

LOG_MAX_AGE_DAYS="${LOG_MAX_AGE_DAYS:-7}"
LOG_MAX_SIZE_MB="${LOG_MAX_SIZE_MB:-2048}"

BIN_DIR="$HOME/.local/bin"
CLEANUP_SCRIPT="${BIN_DIR}/omniverse-log-cleanup.sh"
UNIT_DIR="$HOME/.config/systemd/user"
UNIT_NAME="omniverse-log-cleanup"

echo "Omniverse 로그 자동 정리 설정 시작"

echo "[1/3] 정리 스크립트 배포: ${CLEANUP_SCRIPT}"
mkdir -p "${BIN_DIR}"
cat > "${CLEANUP_SCRIPT}" <<EOF
#!/bin/bash
LOG_DIR="\$HOME/.nvidia-omniverse/logs"
MAX_AGE_DAYS="\${LOG_MAX_AGE_DAYS:-${LOG_MAX_AGE_DAYS}}"
MAX_SIZE_MB="\${LOG_MAX_SIZE_MB:-${LOG_MAX_SIZE_MB}}"

[ -d "\${LOG_DIR}" ] || exit 0

before_kb=\$(du -sk "\${LOG_DIR}" | awk '{print \$1}')

find "\${LOG_DIR}" -type f -mtime +"\${MAX_AGE_DAYS}" -delete

max_kb=\$((MAX_SIZE_MB * 1024))
total_kb=\$(du -sk "\${LOG_DIR}" | awk '{print \$1}')
if [ "\${total_kb}" -gt "\${max_kb}" ]; then
    # 오래된 파일부터 삭제 (최근 60분 내 수정된 파일 제외)
    while IFS= read -r -d '' entry; do
        [ "\${total_kb}" -le "\${max_kb}" ] && break
        file="\${entry#* }"
        size_kb=\$(du -k "\${file}" | awk '{print \$1}')
        rm -f -- "\${file}" && total_kb=\$((total_kb - size_kb))
    done < <(find "\${LOG_DIR}" -type f -mmin +60 -printf '%T@ %p\0' | sort -z -n)
fi

find "\${LOG_DIR}" -mindepth 1 -type d -empty -delete

after_kb=\$(du -sk "\${LOG_DIR}" | awk '{print \$1}')
echo "omniverse logs: \$((before_kb / 1024))MB -> \$((after_kb / 1024))MB"
EOF
chmod +x "${CLEANUP_SCRIPT}"

echo "[2/3] systemd 사용자 서비스/타이머 생성"
mkdir -p "${UNIT_DIR}"
cat > "${UNIT_DIR}/${UNIT_NAME}.service" <<EOF
[Unit]
Description=Clean up old NVIDIA Omniverse / Isaac Sim logs

[Service]
Type=oneshot
ExecStart=${CLEANUP_SCRIPT}
Nice=19
IOSchedulingClass=idle
EOF

cat > "${UNIT_DIR}/${UNIT_NAME}.timer" <<EOF
[Unit]
Description=Daily cleanup of NVIDIA Omniverse / Isaac Sim logs

[Timer]
OnStartupSec=5min
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "[3/3] 타이머 활성화 및 1회 즉시 실행"
systemctl --user daemon-reload
systemctl --user enable --now "${UNIT_NAME}.timer"
systemctl --user start "${UNIT_NAME}.service" || true

echo "Omniverse 로그 자동 정리 설정 완료"
echo "  - 보존 기간: ${LOG_MAX_AGE_DAYS}일, 최대 크기: ${LOG_MAX_SIZE_MB}MB"
echo "  - 상태 확인: systemctl --user list-timers ${UNIT_NAME}.timer"
echo "  - 실행 기록: journalctl --user -u ${UNIT_NAME}.service"
