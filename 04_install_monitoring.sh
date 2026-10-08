#!/bin/bash
set -e

# 중앙 모니터링 서버(krinfra) 연동: 이 워크스테이션의 CPU/RAM/디스크/네트워크/SMART, NVIDIA GPU, Sunshine 상태를
# 수집할 수 있게 에이전트를 설치합니다. 02_install_dev_stack.sh(Docker + NVIDIA Container Toolkit) 이후에 실행합니다.
#
#   bash 04_install_monitoring.sh
#   GPU_EXPORTER=nvidia_smi bash 04_install_monitoring.sh   # DCGM 대신 nvidia-smi 기반 exporter 강제
#
# - 모니터링 대상 워크스테이션은 모두 NVIDIA GPU를 갖고 있다는 전제입니다. GPU를 인식하지 못하면 중단합니다.
# - NVIDIA 드라이버, CUDA, Isaac Sim, Sunshine 설정은 변경하지 않습니다. Docker 재시작, apt upgrade, 재부팅도 하지 않습니다.
# - 여러 번 실행해도 안전합니다(이미 동작 중인 항목은 건너뜁니다).
# - 방화벽(UFW)이 켜져 있을 때만 규칙 추가 여부를 묻습니다(기본값: 추가하지 않음).
# - 소프트웨어 버전(드라이버, 커널, CUDA, Isaac Sim/Lab, ROS 2, Sunshine, Docker)과 GUI 세션 상태, 재부팅 위험을 기록합니다.
#   변경 이력은 중앙 서버가 보관합니다. 개발자의 프로젝트, 소스 코드, 데이터는 수집하지 않습니다.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

MONITORING_SERVER_IP="${MONITORING_SERVER_IP:-192.168.101.218}"

if [ "$(id -u)" -eq 0 ]; then
    echo "오류: root가 아닌 일반 사용자로 실행하세요 (필요한 곳에서 sudo를 사용합니다)." >&2
    exit 1
fi

echo "모니터링 에이전트 설치 시작 (중앙 서버: ${MONITORING_SERVER_IP})"
sudo -v

echo "[1/7] NVIDIA GPU 확인"
if ! lspci 2>/dev/null | grep -qi 'nvidia'; then
    echo "오류: NVIDIA GPU가 감지되지 않습니다. 모니터링 대상은 NVIDIA GPU 워크스테이션입니다." >&2
    exit 1
fi
if ! nvidia-smi >/dev/null 2>&1; then
    echo "오류: nvidia-smi가 동작하지 않습니다. 01_install_base.sh로 드라이버를 설치하고 재부팅했는지 확인하세요." >&2
    exit 1
fi
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader | sed 's/^/  - /'

echo "[2/7] Node Exporter"
bash install/install_node_exporter.sh

echo "[3/7] NVIDIA GPU Exporter"
bash install/install_gpu_exporter.sh
# shellcheck source=/dev/null
. /etc/krinfra-monitoring.env

echo "[4/7] Sunshine 상태 수집기"
bash install/install_sunshine_metrics.sh

echo "[5/7] 시스템 기준 정보 수집기 (드라이버/커널/CUDA/Isaac Sim 버전, GUI 세션, 재부팅 위험)"
bash install/install_system_info_metrics.sh

echo "[6/7] 방화벽 확인"
if sudo ufw status 2>/dev/null | grep -q 'Status: active'; then
    echo "  - UFW가 활성화되어 있습니다. 중앙 서버(${MONITORING_SERVER_IP})에서 다음 포트에 접근해야 합니다:"
    echo "      9100/tcp (Node Exporter), ${GPU_EXPORTER_PORT}/tcp (GPU Exporter)"
    answer="n"
    if [ -t 0 ]; then
        read -r -p "  ${MONITORING_SERVER_IP} 출발지만 허용하는 규칙을 추가할까요? [y/N] " answer
    fi
    case "$answer" in
        y|Y|yes|YES)
            for p in 9100 "${GPU_EXPORTER_PORT}"; do
                sudo ufw allow from "${MONITORING_SERVER_IP}" to any port "${p}" proto tcp comment 'krinfra monitoring'
            done
            ;;
        *)
            echo "  - 규칙을 추가하지 않았습니다. 필요하면 직접 실행하세요:"
            echo "      sudo ufw allow from ${MONITORING_SERVER_IP} to any port 9100 proto tcp"
            echo "      sudo ufw allow from ${MONITORING_SERVER_IP} to any port ${GPU_EXPORTER_PORT} proto tcp"
            ;;
    esac
else
    echo "  - UFW 비활성: 규칙 추가 불필요"
fi

echo "[7/7] 점검"
bash install/verify_monitoring.sh || true

echo ""
echo "모니터링 에이전트 설치 완료."
echo "위 '등록 정보'를 중앙 서버(krinfra) 관리자에게 전달하면 Prometheus/Grafana에 등록됩니다."
