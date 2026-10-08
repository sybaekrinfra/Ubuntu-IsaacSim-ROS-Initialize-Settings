#!/bin/bash
set -e

# 워크스테이션 모니터링 1/3: Node Exporter
# - Ubuntu 공식 패키지 prometheus-node-exporter를 사용합니다(보안 업데이트는 apt로 받습니다).
#   함께 설치하는 prometheus-node-exporter-collectors가 SMART(smartmon), NVMe, apt 상태를
#   textfile(/var/lib/prometheus/node-exporter)로 제공합니다.
# - 이미 설치되어 동작 중이면 아무것도 바꾸지 않습니다. 여러 번 실행해도 안전합니다.
# - 패키지 기본값대로 0.0.0.0:9100에서 리슨하고, 중앙 모니터링 서버(krinfra)가 수집합니다.
# - apt upgrade, 재부팅, 다른 서비스 재시작은 하지 않습니다.

NODE_EXPORTER_PORT=9100
PKG="prometheus-node-exporter"
SERVICE="prometheus-node-exporter.service"

metrics_ok() {
    curl -fsS --max-time 5 "http://127.0.0.1:${NODE_EXPORTER_PORT}/metrics" 2>/dev/null \
        | grep -q '^node_cpu_seconds_total'
}

echo "Node Exporter 설치 시작"

echo "[1/4] 기존 설치 확인"
if systemctl is-active --quiet node_exporter.service 2>/dev/null; then
    # 중앙 서버 Ansible(바이너리 설치)이나 다른 방식으로 이미 설치된 경우: 그대로 사용
    echo "  - node_exporter.service(바이너리 설치)가 이미 동작 중입니다. 변경하지 않습니다."
    metrics_ok && echo "  - http://127.0.0.1:${NODE_EXPORTER_PORT}/metrics 응답 정상"
    exit 0
fi

if dpkg -s "${PKG}" >/dev/null 2>&1 && systemctl is-active --quiet "${SERVICE}"; then
    echo "  - ${PKG} $(dpkg-query -W -f='${Version}' "${PKG}")이(가) 이미 동작 중입니다. 설치를 건너뜁니다."
else
    if ss -Htln "sport = :${NODE_EXPORTER_PORT}" | grep -q .; then
        echo "오류: ${NODE_EXPORTER_PORT}/tcp 포트를 다른 프로세스가 사용 중입니다." >&2
        sudo ss -Htlnp "sport = :${NODE_EXPORTER_PORT}" >&2 || true
        exit 1
    fi

    echo "[2/4] 패키지 설치 (이미 설치된 패키지는 업그레이드하지 않음)"
    sudo apt-get update
    sudo apt-get install -y --no-upgrade \
        prometheus-node-exporter \
        prometheus-node-exporter-collectors \
        smartmontools

    echo "[3/4] 서비스 활성화"
    sudo systemctl enable --now "${SERVICE}"
fi

echo "[4/4] 동작 확인"
for _ in $(seq 1 10); do
    metrics_ok && break
    sleep 1
done
if ! metrics_ok; then
    echo "오류: http://127.0.0.1:${NODE_EXPORTER_PORT}/metrics 응답이 없습니다." >&2
    echo "  확인: systemctl status ${SERVICE} --no-pager" >&2
    exit 1
fi
version="$(curl -fsS --max-time 5 "http://127.0.0.1:${NODE_EXPORTER_PORT}/metrics" \
    | sed -n 's/^node_exporter_build_info{.*version="\([^"]*\)".*/\1/p')"
echo "Node Exporter 동작 확인 완료 (version ${version}, port ${NODE_EXPORTER_PORT})"
echo "  - textfile 디렉터리: /var/lib/prometheus/node-exporter"
