# Ubuntu Setting 스크립트

이 저장소는 새 Ubuntu 워크스테이션을 빠르게 세팅하기 위한 스크립트 모음입니다.

> [!CAUTION]
> 현재 설치는 Ubuntu Server 기준입니다. Ubuntu Desktop에서 GNOME을 계속 사용하려면 `install/install_desktop.sh`(Xfce + LightDM 자동 로그인)와 `.desktop` 바로가기 복사 단계를 건너뛰세요. LightDM을 기본 디스플레이 매니저로 지정하므로 이미 GDM 등을 쓰고 있다면 충돌할 수 있습니다.

현재 구조는 하나의 공통 스크립트 세트로 통합되어 있고, Ubuntu 버전에 맞는 ROS 2 배포판을 자동 선택합니다.

## 지원 범위

| Ubuntu | 코드명 | ROS 2 | 지원 범위 |
| --- | --- | --- | --- |
| 22.04 | Jammy | Humble | 전체 설치 스크립트 지원 |
| 24.04 | Noble | Jazzy | 전체 설치 스크립트 권장 조합 |
| 26.04 | Resolute | Lyrical | ROS 2 설치만 지원, Isaac Sim 제외 |

`Noble`은 ROS 2 배포판이 아니라 Ubuntu 24.04의 코드명입니다. Ubuntu 26.04의 코드명은 `Resolute`이며 대응하는 안정 ROS 2 배포판은 `Lyrical`입니다.

ROS 2 Lyrical은 Ubuntu 26.04를 공식 지원하지만, 현재 Isaac Sim의 공식 지원 OS는 Ubuntu 22.04/24.04이고 권장 ROS 2 배포판은 Humble/Jazzy입니다. 따라서 Ubuntu 26.04에서는 `02_install_dev_stack.sh` 전체 실행 대신 필요한 개별 설치 스크립트를 선택해 사용하세요.

- [ROS 2 Lyrical Ubuntu 지원](https://docs.ros.org/en/lyrical/Installation/Alternatives/Ubuntu-Install-Binary.html)
- [Isaac Sim ROS 2 지원 조합](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/install_ros.html)

`ROS_DISTRO` 환경 변수를 직접 지정할 수도 있지만, 호스트 Ubuntu에서 바이너리 패키지를 제공하는 조합이어야 합니다.

## 구성

- `00_modify.sh`
  - 이미 세팅된 PC(NoMachine/XRDP로 쓰던 PC, `xfce` 세션으로 자동 로그인하던 PC, GDM을 쓰던 PC 등)를 현재 저장소 기준 설정으로 갱신합니다. 여러 번 실행해도 안전하며, 저장소를 업데이트(`git pull`)한 뒤 다시 실행하면 됩니다.
  - `install/install_desktop.sh`로 Xfce/Xubuntu 기본 설정 패키지를 설치하고, 기본 디스플레이 매니저를 LightDM으로 바꾼 뒤 `user-session=xubuntu` 자동 로그인을 설정합니다.
  - Sunshine이 설치되어 있지 않을 때만 `install/install_sunshine.sh`를 실행합니다. 이미 설치된 PC에서는 페어링이나 비밀번호 같은 기존 설정을 건드리지 않습니다.
  - 패널 레이아웃 마커(`~/.config/xfce4/panel/.xubuntu-layout-v5`)를 지운 뒤 `install/copy_files.sh`를 실행해 바로가기, 패널, 배경화면을 다시 구성합니다. 로컬 Xubuntu 세션에서 실행하면 바로 적용하고, XRDP/NoMachine 가상 세션이나 SSH에서 실행하면 다음 Xubuntu 로그인 때 적용합니다(배경화면은 현재 세션에 있는 모니터에만 적용되기 때문입니다).
  - NoMachine/XRDP는 설치되어 있어도 변경하지 않습니다.
  - 마지막에 재부팅 여부를 묻습니다.

- `01_install_base.sh`
  - 기본 패키지를 설치합니다.
  - `install/set-cpu-performance.sh`를 호출해 CPU governor를 performance로 설정합니다.
  - NVIDIA 드라이버를 설치합니다.
  - 설치가 끝나면 재부팅합니다.

- `02_install_dev_stack.sh`
  - VSCode, Chrome, Xfce Desktop, Sunshine을 설치합니다.
  - Sunshine은 Moonlight 클라이언트로 접속하는 자체 호스팅 스트리밍 서버입니다.
  - `install/install_desktop.sh`로 Xfce Desktop을 설치하고 LightDM 자동 로그인을 구성해, 재부팅 후 사람이 직접 로그인하지 않아도 Xfce 세션과 Sunshine이 자동으로 뜨도록 합니다.
  - XRDP/NoMachine 설치 스크립트는 `install/legacy/`로 옮기고 기본 실행에서는 주석 처리했습니다. 필요하면 직접 호출하세요.
  - Xfce의 기본 Terminal Emulator를 Xfce Terminal로 설정합니다.
  - Docker를 설치합니다.
  - `install/install_ros2.sh`를 호출해 Ubuntu 버전에 맞는 ROS 2를 설치합니다.
  - NVIDIA Container Toolkit을 설치합니다.
  - Isaac Sim을 설치합니다.
  - 바탕화면과 자동실행 바로가기를 복사합니다.

- `03_install_isaac_lab.sh`
  - NVIDIA 드라이버 상태를 확인합니다.
  - `install/install_isaaclab.sh`를 호출해 Isaac Lab을 설치합니다.
  - 설치 확인을 위해 `create_empty.py` 튜토리얼을 headless로 30초간 실행합니다(무한 루프 스크립트라 `timeout`으로 강제 종료하며, 이는 정상 동작입니다).

- `04_install_monitoring.sh`
  - 중앙 모니터링 서버(krinfra, 192.168.101.218)가 이 워크스테이션을 수집할 수 있게 모니터링 에이전트를 설치합니다. 수집 대상은 CPU, RAM, 디스크, 네트워크, SMART, **NVIDIA GPU**, Sunshine 상태입니다. `02_install_dev_stack.sh`(Docker + NVIDIA Container Toolkit) 이후에 실행합니다.
  - **모니터링 대상 PC는 모두 NVIDIA GPU를 갖고 있다는 전제입니다.** `lspci`에서 NVIDIA GPU가 보이지 않거나 `nvidia-smi`가 동작하지 않으면 아무것도 설치하지 않고 중단합니다.
  - NVIDIA 드라이버, CUDA, Isaac Sim, Sunshine 설정은 변경하지 않습니다. Docker 재시작, `apt upgrade`, 재부팅도 하지 않습니다. 여러 번 실행해도 안전합니다.
  - 순서: GPU 확인 → `install/install_node_exporter.sh` → `install/install_gpu_exporter.sh` → `install/install_sunshine_metrics.sh` → 방화벽 확인 → `install/verify_monitoring.sh`
  - UFW가 켜져 있을 때만 중앙 서버 IP에서 오는 9100과 GPU exporter 포트를 허용할지 묻습니다(기본 N). 중앙 서버 IP는 `MONITORING_SERVER_IP`로 바꿀 수 있습니다.
  - 마지막에 출력되는 **"중앙 서버 관리자에게 전달할 등록 정보"**(Ansible 인벤토리 예시)를 관리자에게 전달하면 Prometheus/Grafana에 등록됩니다. 워크스테이션 호스트명은 PC마다 겹칠 수 있어(`krinfra`, `mkt` 등) 중앙에서는 별칭과 IP로 구분합니다.
  - `install/install_node_exporter.sh`: Ubuntu 패키지 `prometheus-node-exporter`(9100)와 `prometheus-node-exporter-collectors`(SMART/NVMe/apt textfile), `smartmontools`를 설치합니다. 이미 동작 중인 Node Exporter(패키지 또는 바이너리)가 있으면 그대로 둡니다.
  - `install/install_gpu_exporter.sh`: `GPU_EXPORTER=auto`(기본) | `dcgm` | `nvidia_smi`
    - auto: Docker NVIDIA 런타임이 있으면 NVIDIA DCGM Exporter 컨테이너(`krinfra-dcgm-exporter`, 9400/tcp, `nvcr.io/nvidia/k8s/dcgm-exporter:4.6.1-4.8.4`)를 실행합니다. GPU 사용률/VRAM/온도/전력 필수 메트릭이 나오는지 확인하고, 실패하면 컨테이너를 지우고 `nvidia_gpu_exporter` 1.15.1 deb(9835/tcp, SHA-256 검증)로 전환합니다.
    - 이미 `nv-hostengine`(DCGM)을 쓰는 PC이거나 Docker NVIDIA 런타임이 없으면 바로 nvidia_smi 방식을 씁니다. Container Toolkit은 설치하지 않습니다.
    - DCGM 수집 항목은 `install/dcgm-counters.csv`입니다. 이미지 기본 항목에 **전력 제한**(`DCGM_FI_DEV_ENFORCED_POWER_LIMIT`, `DCGM_FI_DEV_POWER_MGMT_LIMIT`)과 **전력 제한으로 인한 스로틀링 시간**(`DCGM_FI_DEV_POWER_VIOLATION`)을 더한 파일입니다.
      - 이 파일은 `/etc/krinfra/dcgm-counters.csv`에 설치되고 컨테이너에 마운트됩니다.
      - 누적 전력량(`DCGM_FI_DEV_TOTAL_ENERGY_CONSUMPTION`)은 기본 항목에 포함되어 있습니다.
      - 이 파일이 바뀐 뒤 스크립트를 다시 실행하면, 동작 중인 DCGM 컨테이너를 새 항목으로 다시 만듭니다.
    - 결과(방식, 포트)는 `/etc/krinfra-monitoring.env`에 기록합니다. 이미 정상 동작 중이면 건너뛰며, 다시 설치하려면 `FORCE=1`을 지정합니다.
    - **nvidia_smi → DCGM 전환** (DCGM 권장): 먼저 `sudo docker info --format '{{json .Runtimes}}' | grep -o nvidia`로 Docker NVIDIA 런타임을 확인합니다. 없으면 `bash install/install_nvidia_container_toolkit.sh`를 실행합니다. **이 스크립트는 Docker를 재시작하므로 실행 중인 컨테이너가 멈춥니다.** 그다음 `bash 04_install_monitoring.sh`(또는 `bash install/install_gpu_exporter.sh`)를 다시 실행하면, auto 모드가 nvidia_smi 사용 중인 것을 감지하고 DCGM 전환을 시도합니다. DCGM 검증에 성공하면 기존 nvidia_gpu_exporter는 자동으로 제거되고, 실패하면 그대로 남습니다. 전환 후에는 중앙 서버 관리자에게 알려 인벤토리의 `gpu_exporter_type`을 `dcgm`으로 바꾸도록 합니다.
    - 드라이버를 업데이트한 뒤 재부팅하지 않으면 NVML 버전 불일치로 `nvidia-smi`와 exporter가 모두 실패합니다. 드라이버 변경 후에는 재부팅하세요.
  - `install/install_sunshine_metrics.sh`: 30초마다 Sunshine 프로세스 실행 여부, 47989/tcp LISTEN 여부, 사용자 서비스(`app-dev.lizardbyte.app.Sunshine`) 상태를 Node Exporter textfile(`sunshine.prom`)로 기록합니다(`krinfra-sunshine-metrics.timer`). Sunshine을 재시작하거나 설정을 바꾸지 않으며, Moonlight 세션 연결 여부는 수집하지 않습니다.
  - `install/verify_monitoring.sh [IP]`: 인자 없이 실행하면 이 PC를 점검하고(서비스, UFW 포함), IP를 주면 다른 PC(예: 중앙 서버)에서 원격으로 점검합니다(HTTP만). Node 또는 GPU가 실패하면 종료 코드 1을 반환합니다.
  - 제거:
    ```bash
    sudo systemctl disable --now krinfra-sunshine-metrics.timer
    sudo rm /etc/systemd/system/krinfra-sunshine-metrics.{service,timer} /usr/local/lib/krinfra/sunshine_metrics.sh
    sudo docker rm -f krinfra-dcgm-exporter        # DCGM 방식
    sudo apt-get remove nvidia-gpu-exporter         # nvidia_smi 방식
    sudo apt-get remove prometheus-node-exporter prometheus-node-exporter-collectors
    sudo rm -f /etc/krinfra-monitoring.env && sudo systemctl daemon-reload
    ```

- `install/`
  - 개별 설치 스크립트가 들어 있습니다.
  - `install_desktop.sh`는 Xfce Desktop 패키지(`xubuntu-default-settings` 포함)를 설치하고, LightDM을 기본 디스플레이 매니저로 지정한 뒤(GDM 등 다른 디스플레이 매니저를 쓰고 있었다면 LightDM으로 전환) `/etc/lightdm/lightdm.conf.d/50-autologin.conf`에 현재 사용자로 자동 로그인(`user-session=xubuntu`)하도록 설정합니다. 부팅 시 기대하는 흐름은 `LightDM → 자동 로그인 → Xubuntu 세션 → Sunshine 사용자 서비스 시작 → Moonlight 접속 가능`입니다.
    - `xubuntu-default-settings`는 Xubuntu 기본 배경화면/테마 정보(`xubuntu-wallpapers` 등)를 함께 가져옵니다. 순정 `xfce4`만 설치하면 파란 배경에 Xfce 마스코트(쥐) 로고가 있는 기본 배경화면이 뜨는데, 이 패키지가 있어야 `configure_xfce_panel.sh`가 실제 Xubuntu 배경화면 경로를 알아낼 수 있습니다.
    - `user-session`은 `xfce`가 아니라 반드시 `xubuntu`여야 합니다. `xfce` 세션으로 로그인하면 `XDG_CONFIG_DIRS`에 `/etc/xdg/xdg-xubuntu`가 포함되지 않아서, `xubuntu-default-settings`가 실제로 설치한 `/etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml`(배경화면 등 기본값)을 세션이 아예 찾지 못합니다.
    - `/usr/share/xsessions/xubuntu.desktop`이 없으면 중단합니다.
    - 다른 lightdm 설정 파일(`lightdm.conf` 또는 `lightdm.conf.d/*.conf`)에 이미 `autologin-user`가 지정돼 있으면 충돌을 피하기 위해 덮어쓰지 않고 중단하며, 어느 파일에 무슨 값이 있는지 보여줍니다.
    - `50-autologin.conf`가 이미 원하는 내용이면 아무것도 하지 않고, 다른 내용이 있던 경우에만 타임스탬프를 붙여 백업한 뒤 덮어씁니다.
  - `install_sunshine.sh`는 Cloudsmith 저장소를 등록하고 Sunshine을 설치한 뒤, 사용자를 `input` 그룹에 추가하고 systemd 사용자 서비스(`app-dev.lizardbyte.app.Sunshine`)를 활성화합니다.
    - `~/.config/sunshine/sunshine.conf`에 `capture = x11`을 설정합니다.
    - `sunshine_name`을 `<사용자 이름>_<로컬 IP 마지막 옥텟>`(예: `sybae_215`)으로 설정합니다(기본값은 PC 호스트명). IP를 감지하지 못하면 사용자 이름만 사용합니다.
    - `nvidia-smi`로 NVIDIA 드라이버가 감지되면 `encoder = nvenc`를 설정하고, 감지되지 않으면 기본값(자동 선택)을 유지합니다.
    - 로컬 IP를 감지할 수 있으면 `csrf_allowed_origins = https://<감지된 IP>:47990`을 설정합니다.
    - `~/.local/bin/sunshine-disable-mouse-accel.sh` 훅 스크립트를 배포하고, `global_prep_cmd`에 등록해 매 세션 시작마다 백그라운드로 실행되게 합니다. 이 훅은 Sunshine이 생성하는 가상 마우스 장치(이름에 `sunshine`이 포함된 libinput 장치)를 찾아 `libinput Accel Profile Enabled`를 flat으로, `libinput Accel Speed`를 -1로 설정해 호스트 X11의 pointer acceleration을 꺼줍니다. 가상 장치는 세션마다 새로 생성되므로 접속할 때마다 자동으로 재적용됩니다.
    - `~/.config/sunshine/apps.json`을 Desktop 항목 하나만 남긴 내용으로 덮어씁니다(Low Res Desktop/Steam Big Picture 제거). 재설치·재실행 시 매번 이 상태로 리셋됩니다.
    - `sunshine --creds`로 웹 UI 로그인 아이디/비밀번호를 `<사용자 이름> / 1`로 자동 설정합니다. 비밀번호가 매우 단순하니 필요하면 웹 UI에서 바꾸세요.
    - Sunshine 원본 systemd 유닛에는 이미 `ExecStartPre=/bin/sleep 5`, `Restart=on-failure`, `RestartSec=5`가 들어있습니다. 예전 버전의 이 스크립트가 만들어 둔, 그것과 완전히 중복되는 override(`~/.config/systemd/user/app-dev.lizardbyte.app.Sunshine.service.d/override.conf`)가 남아 있으면 제거하고, 다른 내용이 섞여 있으면 손대지 않습니다.
    - Xfce는 로그인해도 `graphical-session.target`을 활성화하지 않는 경우가 있어 `WantedBy=graphical-session.target`만으로는 서비스가 자동 시작되지 않을 수 있습니다. 이를 보완하기 위해 `~/.config/autostart/sunshine-systemd.desktop`을 만들어 Xfce 로그인 직후 `systemctl --user start app-dev.lizardbyte.app.Sunshine.service`를 명시적으로 실행합니다.
    - 설치 후 로그아웃/재로그인이 필요하며, 웹 UI는 `https://<감지된 IP 또는 localhost>:47990`입니다.
    - 클라이언트 PIN 페어링은 스크립트가 자동으로 처리하지 않습니다. 아래 "Sunshine 최초 접속 설정"을 따라 직접 진행하세요.
  - `legacy/`에는 더 이상 기본 실행에 포함되지 않는 XRDP/NoMachine 설치 스크립트(`install_xrdp.sh`, `install_nm.sh`, `nm/nm.deb`)가 들어 있습니다.
  - `install_ros2.sh`는 `jammy -> humble`, `noble -> jazzy`, `resolute -> lyrical`로 자동 분기합니다.
  - `install_omniverse_log_cleanup.sh`는 Isaac Sim/Omniverse Kit이 실행할 때마다 쌓는 `~/.nvidia-omniverse/logs`를 자동으로 정리합니다. `02_install_dev_stack.sh`의 Isaac Sim 설치 직후 실행됩니다.
    - `~/.local/bin/omniverse-log-cleanup.sh`를 배포하고, systemd 사용자 타이머(`omniverse-log-cleanup.timer`)로 부팅 5분 후와 매일 1회 실행합니다.
    - `LOG_MAX_AGE_DAYS`(기본 7)일보다 오래된 로그 파일을 삭제하고, 그래도 `LOG_MAX_SIZE_MB`(기본 2048)MB를 넘으면 오래된 파일부터 지웁니다. 최근 60분 안에 수정된 파일은 실행 중인 세션의 로그일 수 있어 크기 정리에서 제외합니다.
    - 값을 바꾸려면 `LOG_MAX_AGE_DAYS=3 LOG_MAX_SIZE_MB=1024 bash install/install_omniverse_log_cleanup.sh`처럼 다시 실행하세요. 수동 정리는 `systemctl --user start omniverse-log-cleanup.service`, 기록은 `journalctl --user -u omniverse-log-cleanup.service`로 확인합니다.
  - `install_isaaclab.sh`는 기본적으로 Isaac Lab `v3.0.0-beta2`를 `~/IsaacLab`에 클론하고, `~/isaacsim`(Isaac Sim 6.0.1 설치 경로)를 `_isaac_sim`으로 심볼릭 링크한 뒤 `./isaaclab.sh --install`을 실행합니다. `ISAACLAB_VERSION`, `ISAACSIM_DIR`, `ISAACLAB_DIR` 환경 변수로 버전과 경로를 바꿀 수 있습니다. `install/install_isaacsim.sh`로 Isaac Sim을 먼저 설치해야 합니다.
  - `copy_files.sh`는 `desktop/` 폴더의 바로가기 파일 중 `htop.desktop`과 `nvidia-smi.desktop`을 `~/.config/autostart`에 복사하고, 나머지는 `~/Desktop`에 복사합니다.
  - 바로가기 복사 후 사용자별 기본 설정과 무관하게 Greybird/elementary-xfce 테마, Xubuntu 기본 배경화면, 단일 하단 패널을 구성합니다. 배경화면은 `/etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml`(`xubuntu-default-settings`가 설치한 시스템 기본값, `xfce` 세션에서는 안 보이고 `xubuntu` 세션에서만 XDG_CONFIG_DIRS에 잡히는 경로라 `/etc/xdg/xfce4/...`도 폴백으로 확인)에서 실제 경로를 읽어와, 현재 세션에 존재하는 모든 모니터의 `last-image` 속성에 그대로 적용합니다.
  - 하단 패널은 Whisker Menu, 작업 창 버튼, Terminal Emulator/Chrome/Visual Studio Code/Isaac Sim 바로가기, 알림/네트워크/배터리/소리/시계 순서로 구성됩니다. Xfce 세션이 실행 중이 아니면 다음 로그인 때 자동 적용됩니다.
  - 기존 패널 설정은 `~/.config/xfce4/panel-backup-before-layout-v5/`에 한 번 백업합니다.

- `desktop/`
  - `.desktop` 바로가기 파일이 들어 있습니다.

## Sunshine 최초 접속 설정

웹 UI 로그인 아이디/비밀번호는 `install_sunshine.sh`가 `<사용자 이름> / 1`로 자동 설정하지만, 클라이언트 페어링은 자동화되지 않습니다. 최초 1회는 직접 다음 순서로 진행해야 합니다.

1. 호스트에서 웹 UI(`https://<호스트 IP>:47990`)에 접속해 `<사용자 이름> / 1`로 로그인합니다(필요하면 이 자리에서 비밀번호를 바꾸세요).
2. 접속하려는 클라이언트 쪽 Moonlight 앱에서 이 호스트로 접속을 시도합니다.
3. Moonlight에 PIN 번호와 컴퓨터 이름이 표시되면, 방금 로그인한 Sunshine 웹 UI의 PIN 메뉴에서 그 PIN과 (원하는) 기기 이름을 입력해 페어링을 완료합니다. 이 기기 이름은 클라이언트를 구분하기 위한 참고용 라벨일 뿐이라 아무 값이나 입력해도 됩니다.

이 PIN은 클라이언트를 새로 연결할 때마다 매번 새로 발급되는 값이라 스크립트로 미리 넣어둘 수 없습니다. 새 클라이언트를 추가할 때마다 2~3단계를 반복하세요.

`02_install_dev_stack.sh` 실행 후 재부팅하면 기대하는 부팅 흐름은 다음과 같습니다.

```text
LightDM
  ↓
<사용자> 자동 로그인
  ↓
Xfce 세션 생성
  ↓
Xfce autostart (~/.config/autostart/sunshine-systemd.desktop)
  ↓
systemctl --user start app-dev.lizardbyte.app.Sunshine.service
  ↓
Moonlight 접속 가능
```

재부팅 후 상태를 확인하려면:

```bash
loginctl list-sessions
systemctl --user status app-dev.lizardbyte.app.Sunshine.service --no-pager
journalctl --user -u app-dev.lizardbyte.app.Sunshine.service -b --no-pager | tail -80
```

## 실행 순서

이미 세팅된 PC의 설정만 최신으로 바꾸려면 다음처럼 실행합니다.

```bash
git pull
bash 00_modify.sh
```

Ubuntu 22.04/24.04에서 전체 스택을 설치하는 순서입니다.

1. `01_install_base.sh`를 실행합니다.
2. 재부팅합니다.
3. `02_install_dev_stack.sh`를 실행합니다.
4. 전체 설치가 끝나면 다시 재부팅합니다.
5. (선택) Isaac Lab이 필요하면 `03_install_isaac_lab.sh`를 실행합니다.
6. 중앙 모니터링(krinfra)에 연결하려면 `04_install_monitoring.sh`를 실행하고, 출력된 등록 정보를 관리자에게 전달합니다.

## 실행 방법

저장소 루트에서 다음처럼 실행합니다.

```bash
bash 01_install_base.sh
bash 02_install_dev_stack.sh
bash 03_install_isaac_lab.sh
bash 04_install_monitoring.sh
```

이미 세팅된 PC를 모니터링에 연결할 때는 `git pull` 후 `bash 04_install_monitoring.sh`만 실행하면 됩니다.

Isaac Lab 버전이나 설치 경로를 바꾸고 싶으면 다음처럼 지정할 수 있습니다.

```bash
ISAACLAB_VERSION=v3.0.0-beta2 bash 03_install_isaac_lab.sh
```

특정 ROS 배포판을 강제로 쓰고 싶으면 다음처럼 지정할 수 있습니다.

```bash
ROS_DISTRO=humble bash install/install_ros2.sh
ROS_DISTRO=jazzy bash install/install_ros2.sh
ROS_DISTRO=lyrical bash install/install_ros2.sh
```

Ubuntu 26.04에서 ROS 2 Lyrical만 설치하려면 자동 감지를 사용합니다.

```bash
bash install/install_ros2.sh
```

`ROS_DISTRO` 지정은 Ubuntu와 ROS 2의 공식 지원 조합을 바꾸지 않습니다. 예를 들어 Ubuntu 22.04에서 Jazzy 바이너리 설치를 강제하는 용도로 사용하면 안 됩니다.

## 참고

- `02_install_dev_stack.sh`는 자동 재개 방식이 아닙니다. 첫 번째 재부팅 후 직접 다시 실행해야 합니다.
- `install/install_ros2.sh`에는 `rosdep init/update`와 기본 Python 개발 패키지가 포함되어 있습니다.
  - `python3-pip`
  - `python3-venv`
  - `python3-colcon-common-extensions`
- Docker 관련 단계는 호스트 시스템용입니다. 이미 별도의 Docker 이미지가 있다면 그 이미지를 계속 사용하셔도 됩니다.

## 주의사항

- 네트워크 연결이 필요합니다.
- 일부 단계는 `sudo` 권한이 필요합니다.
- 설치 스크립트는 NVIDIA 580 드라이버를 지정합니다. Isaac Sim 버전별 최소 드라이버 요구사항과 Ubuntu 저장소의 제공 버전을 실행 전에 확인하세요. Isaac Sim 6.0.1 공식 요구사항에는 Linux 595.58.03이 기재되어 있습니다.
- ROS 2 설치는 GitHub 최신 릴리스 API에 의존합니다.
- Ubuntu 버전과 ROS 2 배포판 조합은 함께 맞춰야 합니다. 이 스크립트의 기본 조합은 `22.04/Humble`, `24.04/Jazzy`, `26.04/Lyrical`입니다.
- Ubuntu 26.04/Lyrical은 ROS 2 단독 설치 범위입니다. Isaac Sim과 ROS 2 Bridge까지 포함하는 전체 환경은 Ubuntu 24.04/Jazzy를 권장합니다.
- [Isaac Sim 시스템 요구사항](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/requirements.html)

## 디렉터리 예시

```text
Ubuntu Setting/
├── 00_modify.sh
├── 01_install_base.sh
├── 02_install_dev_stack.sh
├── 03_install_isaac_lab.sh
├── 04_install_monitoring.sh
├── desktop/
│   ├── code.desktop
│   ├── google-chrome.desktop
│   ├── htop.desktop
│   ├── isaac-sim.desktop
│   ├── isaac-sim-newton.desktop
│   ├── nvidia-smi.desktop
│   └── xfce4-terminal-emulator.desktop
├── install/
│   ├── copy_files.sh
│   ├── configure_xfce_panel.sh
│   ├── dcgm-counters.csv
│   ├── install_chrome.sh
│   ├── install_desktop.sh
│   ├── install_gpu_exporter.sh
│   ├── install_isaaclab.sh
│   ├── install_isaacsim.sh
│   ├── install_node_exporter.sh
│   ├── install_nvidia_container_toolkit.sh
│   ├── install_ros2.sh
│   ├── install_sunshine.sh
│   ├── install_sunshine_metrics.sh
│   ├── install_vscode.sh
│   ├── set-cpu-performance.sh
│   ├── verify_monitoring.sh
│   └── legacy/
│       ├── install_xrdp.sh
│       ├── install_nm.sh
│       └── nm/
│           └── nm.deb
└── README.md
```
