#!/bin/bash
set -e

# 워크스테이션 모니터링 2/3: NVIDIA GPU Exporter
# 모니터링 대상 워크스테이션은 모두 NVIDIA GPU를 갖고 있다는 전제입니다. GPU나 드라이버를 인식하지 못하면 중단합니다.
#
# 방식 (GPU_EXPORTER 환경 변수, 기본 auto)
#   dcgm       : NVIDIA DCGM Exporter 컨테이너 (krinfra-dcgm-exporter, 9400/tcp)
#                Docker와 NVIDIA Container Toolkit(02_install_dev_stack.sh에서 설치)이 필요합니다.
#   nvidia_smi : nvidia_gpu_exporter deb 패키지 (systemd, 9835/tcp). nvidia-smi만 있으면 됩니다.
#   auto       : 조건이 되면 dcgm을 시도합니다. 필수 메트릭을 확인하지 못하면 컨테이너를 지우고 nvidia_smi로 전환합니다.
#
# NVIDIA 드라이버, CUDA, Container Toolkit은 설치하거나 변경하지 않습니다. Docker도 재시작하지 않습니다.
# 결과(방식과 포트)는 /etc/krinfra-monitoring.env에 기록하고, verify_monitoring.sh가 이 값을 사용합니다.
# nvidia_smi → DCGM 전환: Docker NVIDIA 런타임이 있으면 이 스크립트(또는 04_install_monitoring.sh)를 다시 실행하기만 하면
#   auto 모드가 DCGM 전환을 시도합니다. 성공하면 기존 nvidia_gpu_exporter를 자동으로 제거하고, 실패하면 그대로 둡니다.
# 여러 번 실행해도 안전합니다. 이미 정상 동작 중이면 건너뜁니다(FORCE=1이면 다시 설치합니다).

GPU_EXPORTER="${GPU_EXPORTER:-auto}"
FORCE="${FORCE:-0}"
DCGM_EXPORTER_IMAGE="${DCGM_EXPORTER_IMAGE:-nvcr.io/nvidia/k8s/dcgm-exporter:4.6.1-4.8.4}"
DCGM_CONTAINER="krinfra-dcgm-exporter"
DCGM_PORT=9400
NGE_VERSION="1.15.1"
NGE_DEB="nvidia-gpu-exporter_${NGE_VERSION}_linux_amd64.deb"
NGE_URL="https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v${NGE_VERSION}/${NGE_DEB}"
NGE_SHA256="0dc8c2756c6853ec7e6a7c404b229d8f764443bef89f33e13b3c4278b309acd4"   # 공식 checksums.txt 값
NGE_PORT=9835
STATE_FILE="${KRINFRA_STATE_FILE:-/etc/krinfra-monitoring.env}"   # 테스트 시에만 변경

# GeForce/RTX Pro 모두에서 NVML로 제공되는 기본 필드 (프로파일링 DCGM_FI_PROF_* 는 사용하지 않음)
DCGM_REQUIRED="DCGM_FI_DEV_GPU_UTIL DCGM_FI_DEV_FB_USED DCGM_FI_DEV_FB_FREE DCGM_FI_DEV_GPU_TEMP DCGM_FI_DEV_POWER_USAGE"
NGE_REQUIRED="nvidia_smi_utilization_gpu_ratio nvidia_smi_memory_used_bytes nvidia_smi_memory_total_bytes nvidia_smi_temperature_gpu nvidia_smi_power_draw_watts"

missing_metrics() {   # $1=port, $2=필수 메트릭 목록 → 누락된 이름 출력 (응답 없음이면 "NO_RESPONSE")
    local body
    body="$(curl -fsS --max-time 10 "http://127.0.0.1:$1/metrics" 2>/dev/null)" || { echo "NO_RESPONSE"; return; }
    for m in $2; do
        grep -q "^${m}[{ ]" <<<"${body}" || printf '%s ' "${m}"
    done
}

wait_metrics() {      # $1=port, $2=필수 목록, $3=최대 대기(초)
    local miss=""
    for _ in $(seq 1 "$3"); do
        miss="$(missing_metrics "$1" "$2")"
        [ -z "${miss}" ] && return 0
        sleep 1
    done
    echo "  - 확인 실패: ${miss}" >&2
    return 1
}

write_state() {       # $1=type, $2=port
    printf 'GPU_EXPORTER_TYPE=%s\nGPU_EXPORTER_PORT=%s\nGPU_EXPORTER_INSTALLED_AT="%s"\n' "$1" "$2" "$(date '+%F %T %Z')" \
        | sudo tee "${STATE_FILE}" >/dev/null
    sudo chmod 644 "${STATE_FILE}"
}

remove_nvidia_smi_exporter() {
    # DCGM으로 전환했을 때 같은 GPU가 두 번 수집되지 않도록, 이 스크립트가 설치했던 nvidia_gpu_exporter를 정리한다.
    if dpkg -s nvidia-gpu-exporter >/dev/null 2>&1; then
        echo "  - DCGM 전환 완료 → 기존 nvidia_gpu_exporter(9835)를 제거합니다 (중복 수집 방지)."
        sudo systemctl disable --now nvidia_gpu_exporter.service 2>/dev/null || true
        sudo apt-get remove -y nvidia-gpu-exporter
    fi
}

docker_nvidia_ready() {
    command -v docker >/dev/null 2>&1 || return 1
    sudo docker info --format '{{json .Runtimes}}' 2>/dev/null | grep -q '"nvidia"'
}

install_dcgm() {
    echo "  - DCGM Exporter 컨테이너 설치: ${DCGM_EXPORTER_IMAGE}"
    if sudo docker inspect "${DCGM_CONTAINER}" >/dev/null 2>&1; then
        if [ "$(sudo docker inspect -f '{{index .Config.Labels "managed-by"}}' "${DCGM_CONTAINER}")" != "krinfra" ]; then
            echo "오류: '${DCGM_CONTAINER}' 컨테이너가 있지만 이 스크립트가 만든 것이 아닙니다(label managed-by=krinfra 없음). 중단합니다." >&2
            return 2
        fi
        sudo docker rm -f "${DCGM_CONTAINER}" >/dev/null
    fi
    if ss -Htln "sport = :${DCGM_PORT}" | grep -q .; then
        echo "  - ${DCGM_PORT}/tcp 포트를 다른 프로세스가 사용 중입니다." >&2
        return 1
    fi
    if ! sudo docker pull -q "${DCGM_EXPORTER_IMAGE}" >/dev/null; then
        echo "  - DCGM 이미지 다운로드 실패: ${DCGM_EXPORTER_IMAGE}" >&2
        echo "    nvcr.io 접근(DNS/프록시/방화벽) 확인: sudo docker pull ${DCGM_EXPORTER_IMAGE}" >&2
        return 1
    fi
    # 기본 카운터에 프로파일링 필드(dram_active, pcie_tx/rx 등)가 포함되어 있어 SYS_ADMIN이 없으면
    # "Host engine is running as non-root" 에러로 GPU 수집기 초기화에 실패하고 컨테이너가 종료된다.
    sudo docker run -d --name "${DCGM_CONTAINER}" \
        --label managed-by=krinfra \
        --restart unless-stopped \
        --gpus all \
        --cap-add SYS_ADMIN \
        --memory 512m \
        --log-opt max-size=10m --log-opt max-file=3 \
        -p "${DCGM_PORT}:9400" \
        "${DCGM_EXPORTER_IMAGE}" >/dev/null || { echo "  - DCGM 컨테이너 실행 실패 (위 docker 오류 참고)" >&2; return 1; }
    echo "  - 필수 메트릭 확인 중 (최대 90초)"
    if wait_metrics "${DCGM_PORT}" "${DCGM_REQUIRED}" 90; then
        write_state dcgm "${DCGM_PORT}"
        remove_nvidia_smi_exporter
        return 0
    fi
    echo "  - DCGM Exporter 로그 (마지막 20줄):" >&2
    sudo docker logs --tail 20 "${DCGM_CONTAINER}" 2>&1 | sed 's/^/      /' >&2
    sudo docker rm -f "${DCGM_CONTAINER}" >/dev/null
    echo "  - 이 워크스테이션에서는 DCGM Exporter가 부적합하다고 판단해 컨테이너를 제거했습니다." >&2
    return 1
}

install_nvidia_smi() {
    echo "  - nvidia_gpu_exporter ${NGE_VERSION} 설치"
    if ss -Htln "sport = :${NGE_PORT}" | grep -q . && ! systemctl is-active --quiet nvidia_gpu_exporter.service; then
        echo "오류: ${NGE_PORT}/tcp 포트를 다른 프로세스가 사용 중입니다." >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL -o "${tmp}/${NGE_DEB}" "${NGE_URL}"
    echo "${NGE_SHA256}  ${tmp}/${NGE_DEB}" | sha256sum -c - >/dev/null
    echo "  - SHA-256 확인 완료"
    sudo apt-get install -y --no-upgrade "${tmp}/${NGE_DEB}"
    rm -rf "${tmp}"
    sudo systemctl enable --now nvidia_gpu_exporter.service
    echo "  - 필수 메트릭 확인 중 (최대 30초)"
    wait_metrics "${NGE_PORT}" "${NGE_REQUIRED}" 30 || return 1
    write_state nvidia_smi "${NGE_PORT}"
}

echo "NVIDIA GPU Exporter 설치 시작 (방식: ${GPU_EXPORTER})"

echo "[1/4] NVIDIA GPU / 드라이버 확인"
if ! command -v nvidia-smi >/dev/null 2>&1 || ! nvidia-smi >/dev/null 2>&1; then
    echo "오류: nvidia-smi가 동작하지 않습니다. 모니터링 대상 워크스테이션은 NVIDIA GPU와 드라이버가 필수입니다." >&2
    echo "  - 드라이버 설치는 01_install_base.sh에서 하며, 이 스크립트는 드라이버를 변경하지 않습니다." >&2
    echo "  - 드라이버를 업데이트한 뒤 재부팅하지 않았다면 NVML 버전 불일치일 수 있습니다(재부팅 필요)." >&2
    exit 1
fi
nvidia-smi --query-gpu=index,name,driver_version,memory.total --format=csv,noheader | sed 's/^/  - GPU /'

echo "[2/4] 기존 GPU Exporter 확인"
if [ "${FORCE}" != "1" ]; then
    if [ -z "$(missing_metrics "${DCGM_PORT}" "${DCGM_REQUIRED}")" ]; then
        echo "  - DCGM Exporter가 이미 정상 동작 중입니다(${DCGM_PORT}). 건너뜁니다. (재설치: FORCE=1)"
        write_state dcgm "${DCGM_PORT}"
        exit 0
    fi
    if [ -z "$(missing_metrics "${NGE_PORT}" "${NGE_REQUIRED}")" ]; then
        # nvidia_smi 는 대안일 뿐이므로, auto/dcgm 에서 DCGM 조건이 갖춰졌으면 전환을 시도한다(실패 시 기존 유지).
        if [ "${GPU_EXPORTER}" != "nvidia_smi" ] && ! pgrep -x nv-hostengine >/dev/null 2>&1 && docker_nvidia_ready; then
            echo "  - nvidia_gpu_exporter(${NGE_PORT})가 동작 중이지만 DCGM 사용이 가능합니다 → DCGM 전환 시도 (실패하면 기존 유지)"
            UPGRADE_FROM_NVIDIA_SMI=1
        else
            echo "  - nvidia_gpu_exporter가 이미 정상 동작 중입니다(${NGE_PORT}). 건너뜁니다."
            if [ "${GPU_EXPORTER}" != "nvidia_smi" ]; then
                if pgrep -x nv-hostengine >/dev/null 2>&1; then
                    echo "    (DCGM 미사용 이유: nv-hostengine 이 이미 실행 중)"
                else
                    echo "    (DCGM 미사용 이유: Docker NVIDIA 런타임 없음 → bash install/install_nvidia_container_toolkit.sh 실행 후"
                    echo "     이 스크립트를 다시 실행하면 DCGM 으로 전환됩니다. Toolkit 설치는 Docker 를 재시작합니다.)"
                fi
            fi
            write_state nvidia_smi "${NGE_PORT}"
            exit 0
        fi
    fi
fi
[ "${UPGRADE_FROM_NVIDIA_SMI:-0}" = 1 ] || echo "  - 동작 중인 GPU Exporter 없음"

echo "[3/4] 설치 방식 결정"
method="${GPU_EXPORTER}"
if [ "${method}" = "auto" ]; then
    if pgrep -x nv-hostengine >/dev/null 2>&1; then
        echo "  - 이미 DCGM(nv-hostengine)이 실행 중이라 충돌을 피하기 위해 nvidia_smi 방식을 사용합니다."
        method="nvidia_smi"
    elif docker_nvidia_ready; then
        echo "  - Docker NVIDIA 런타임 확인 → DCGM Exporter 시도"
        method="dcgm"
    else
        echo "  - Docker NVIDIA 런타임이 없어 nvidia_smi 방식을 사용합니다 (Container Toolkit은 설치하지 않음)."
        echo "    DCGM을 쓰려면: bash install/install_nvidia_container_toolkit.sh (Docker 재시작 포함) 후 이 스크립트를 다시 실행"
        method="nvidia_smi"
    fi
fi

echo "[4/4] 설치 (${method})"
case "${method}" in
    dcgm)
        if ! docker_nvidia_ready; then
            echo "오류: Docker NVIDIA 런타임이 없습니다. install/install_nvidia_container_toolkit.sh 또는 GPU_EXPORTER=nvidia_smi를 사용하세요." >&2
            exit 1
        fi
        set +e
        install_dcgm
        rc=$?
        set -e
        if [ "${rc}" -ne 0 ]; then
            [ "${rc}" -eq 2 ] && exit 1
            if [ "${UPGRADE_FROM_NVIDIA_SMI:-0}" = 1 ]; then
                echo "  - DCGM 전환 실패 → 기존 nvidia_gpu_exporter(${NGE_PORT})를 그대로 사용합니다."
                write_state nvidia_smi "${NGE_PORT}"
            elif [ "${GPU_EXPORTER}" = "auto" ]; then
                echo "  - nvidia_smi 방식으로 전환합니다."
                install_nvidia_smi
            else
                exit 1
            fi
        fi
        ;;
    nvidia_smi)
        install_nvidia_smi
        ;;
    *)
        echo "오류: GPU_EXPORTER 값은 auto | dcgm | nvidia_smi 중 하나여야 합니다." >&2
        exit 1
        ;;
esac

# shellcheck source=/dev/null
. "${STATE_FILE}"
echo "GPU Exporter 설치 완료: ${GPU_EXPORTER_TYPE} (port ${GPU_EXPORTER_PORT})"
