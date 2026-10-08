#!/bin/bash

# 워크스테이션 모니터링 상태 점검 (읽기 전용)
#
#   bash install/verify_monitoring.sh                # 워크스테이션 자신 점검 (로컬 서비스, 방화벽 포함)
#   bash install/verify_monitoring.sh 192.168.101.215  # 다른 PC(예: 중앙 서버 krinfra)에서 원격 점검 (HTTP만)
#
# 점검 항목: Node Exporter(9100), GPU Exporter(DCGM 9400 또는 nvidia_smi 9835), Sunshine 상태 메트릭
# 마지막에 중앙 서버 관리자에게 전달할 등록 정보(Ansible 인벤토리 예시)를 출력합니다.
# 종료 코드: 0 = Node, GPU 모두 정상 / 1 = 필수 항목 실패

TARGET="${1:-127.0.0.1}"
MONITORING_SERVER_IP="${MONITORING_SERVER_IP:-192.168.101.218}"
LOCAL=0
[ "${TARGET}" = "127.0.0.1" ] && LOCAL=1
fail=0

ok()   { printf '  [OK]   %s\n' "$*"; }
warn() { printf '  [WARN] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; fail=1; }
fetch() { curl -fsS --max-time 10 "http://${TARGET}:$1/metrics" 2>/dev/null; }
val()   { awk -v m="$1" 'index($0, m) == 1 { print $NF; exit }' <<<"$2"; }

echo "모니터링 점검: ${TARGET} $([ ${LOCAL} = 1 ] && echo '(로컬)' || echo '(원격)')"

echo "[1/4] Node Exporter (9100)"
node="$(fetch 9100)"
if grep -q '^node_cpu_seconds_total' <<<"${node}"; then
    ver="$(sed -n 's/^node_exporter_build_info{.*version="\([^"]*\)".*/\1/p' <<<"${node}")"
    nodename="$(sed -n 's/^node_uname_info{.*nodename="\([^"]*\)".*/\1/p' <<<"${node}")"
    ok "응답 정상 (version ${ver}, nodename ${nodename})"
    [ "$(val node_textfile_scrape_error "${node}")" = "0" ] && ok "textfile 수집 정상" || warn "textfile 수집 오류 또는 비활성"
    grep -q '^smartmon_device_smart_healthy' <<<"${node}" && ok "SMART(smartmon) 메트릭 있음" || warn "SMART(smartmon) 메트릭 없음 (prometheus-node-exporter-collectors 확인)"
else
    bad "http://${TARGET}:9100/metrics 응답 없음"
fi

echo "[2/4] NVIDIA GPU Exporter"
gpu_type=""; gpu_port=""
dcgm="$(fetch 9400)"; nge="$(fetch 9835)"
if grep -q '^DCGM_FI_DEV_GPU_UTIL' <<<"${dcgm}"; then
    gpu_type="dcgm"; gpu_port=9400
    for m in DCGM_FI_DEV_GPU_UTIL DCGM_FI_DEV_FB_USED DCGM_FI_DEV_FB_FREE DCGM_FI_DEV_GPU_TEMP DCGM_FI_DEV_POWER_USAGE; do
        grep -q "^${m}{" <<<"${dcgm}" || bad "DCGM 필수 메트릭 누락: ${m}"
    done
    model="$(sed -n 's/^DCGM_FI_DEV_GPU_TEMP{.*modelName="\([^"]*\)".*/\1/p' <<<"${dcgm}" | head -1)"
    ok "DCGM Exporter (9400): ${model} — 사용률 $(val DCGM_FI_DEV_GPU_UTIL "${dcgm}")%, 온도 $(val DCGM_FI_DEV_GPU_TEMP "${dcgm}")°C, 전력 $(val DCGM_FI_DEV_POWER_USAGE "${dcgm}")W, VRAM 사용 $(val DCGM_FI_DEV_FB_USED "${dcgm}")MiB"
elif grep -q '^nvidia_smi_utilization_gpu_ratio' <<<"${nge}"; then
    gpu_type="nvidia_smi"; gpu_port=9835
    for m in nvidia_smi_utilization_gpu_ratio nvidia_smi_memory_used_bytes nvidia_smi_memory_total_bytes nvidia_smi_temperature_gpu nvidia_smi_power_draw_watts; do
        grep -q "^${m}{" <<<"${nge}" || bad "nvidia_smi 필수 메트릭 누락: ${m}"
    done
    model="$(sed -n 's/^nvidia_smi_gpu_info{.*name="\([^"]*\)".*/\1/p' <<<"${nge}" | head -1)"
    ok "nvidia_gpu_exporter (9835): ${model} — 온도 $(val nvidia_smi_temperature_gpu "${nge}")°C, 전력 $(val nvidia_smi_power_draw_watts "${nge}")W"
else
    bad "GPU Exporter 응답 없음 (9400 DCGM / 9835 nvidia_smi). 모니터링 대상 PC는 NVIDIA GPU 필수 → install/install_gpu_exporter.sh 실행"
fi

echo "[3/4] Sunshine 상태 메트릭"
running="$(val sunshine_process_running "${node}")"
if [ -z "${running}" ]; then
    warn "sunshine_* 메트릭 없음 (install/install_sunshine_metrics.sh 미설치)"
else
    [ "${running}" = "1" ] && ok "Sunshine 프로세스 실행 중" || warn "Sunshine 프로세스 미실행"
    [ "$(val 'sunshine_port_listening{' "${node}")" = "1" ] && ok "47989/tcp LISTEN" || warn "47989/tcp LISTEN 아님"
    age=$(( $(date +%s) - $(printf '%.0f' "$(val sunshine_metrics_last_run_timestamp_seconds "${node}")") ))
    [ "${age}" -lt 120 ] && ok "수집 갱신 ${age}초 전" || warn "수집이 ${age}초 동안 갱신되지 않음 (timer 확인)"
    echo "         (Moonlight 세션 연결 여부는 수집하지 않습니다)"
fi

echo "[4/4] 로컬 서비스 / 방화벽"
if [ "${LOCAL}" = 1 ]; then
    for u in prometheus-node-exporter.service node_exporter.service nvidia_gpu_exporter.service krinfra-sunshine-metrics.timer; do
        st="$(systemctl is-active "$u" 2>/dev/null)"
        [ "${st}" = "active" ] && ok "$u active"
    done
    if command -v docker >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        cs="$(sudo docker inspect -f '{{.State.Status}} (restart={{.HostConfig.RestartPolicy.Name}})' krinfra-dcgm-exporter 2>/dev/null)"
        [ -n "${cs}" ] && ok "krinfra-dcgm-exporter 컨테이너: ${cs}"
    fi
    if sudo -n true 2>/dev/null; then
        if sudo ufw status 2>/dev/null | grep -q 'Status: active'; then
            for p in 9100 ${gpu_port}; do
                sudo ufw status | grep -qE "^${p}(/tcp)? +ALLOW +(${MONITORING_SERVER_IP}|Anywhere)" \
                    && ok "UFW: ${p}/tcp 허용됨" \
                    || warn "UFW 활성 — ${p}/tcp 를 ${MONITORING_SERVER_IP} 에서 허용해야 수집됩니다: sudo ufw allow from ${MONITORING_SERVER_IP} to any port ${p} proto tcp"
            done
        else
            ok "UFW 비활성 (방화벽 규칙 불필요)"
        fi
    else
        warn "sudo 비밀번호가 필요해 컨테이너/UFW 점검을 건너뜀 (sudo -v 후 다시 실행)"
    fi
else
    echo "  - 원격 점검 모드: 로컬 서비스/방화벽 점검 생략"
fi

# ── 중앙 서버 등록 정보 ──────────────────────────────────────────────
if [ -z "${model:-}" ] && [ "${LOCAL}" = 1 ] && command -v nvidia-smi >/dev/null 2>&1; then
    model="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)"
fi
ip="${TARGET}"
[ "${LOCAL}" = 1 ] && ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')"
gpu_label="$(sed -e 's/^NVIDIA //' -e 's/^GeForce //' -e 's/ Generation$//' -e 's/ /_/g' <<<"${model:-unknown}")"
alias_suggest="isaac-$(tr '[:upper:]' '[:lower:]' <<<"${gpu_label}" | tr -cd 'a-z0-9')-${ip##*.}"
targets="[node, ssh, sunshine]"; [ -n "${gpu_type}" ] && targets="[node, gpu, ssh, sunshine]"
cat <<EOF

────────── 중앙 서버(krinfra) 관리자에게 전달할 등록 정보 ──────────
/opt/ansible/inventory/hosts.yml  →  gpu_workstations.hosts 아래에 추가 (별칭은 관리자가 결정, 예시는 제안값)
        ${alias_suggest}:
          ansible_host: ${ip}
          monitor_role: isaac-sim
          gpu_model: ${gpu_label}
          monitor_targets: ${targets}
          gpu_exporter_type: ${gpu_type:-<미설치>}
          sunshine_metrics_installed: $([ -n "${running}" ] && echo true || echo false)
          # nodename(실제 호스트명) = ${nodename:-?}  ※ 호스트명은 PC 간 중복될 수 있어 식별에 쓰지 않음
그 다음: cd /opt/ansible && ansible-playbook playbooks/register_prometheus_targets.yml && ansible-playbook playbooks/verify_metrics.yml -l <별칭>
────────────────────────────────────────────────────────────────────
EOF

[ "${fail}" = 0 ] && echo "결과: 정상" || echo "결과: 필수 항목 실패 — 위 [FAIL] 항목 확인"
exit "${fail}"
