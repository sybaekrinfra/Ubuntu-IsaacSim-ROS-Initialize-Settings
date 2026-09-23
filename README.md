# Ubuntu Setting 스크립트

이 저장소는 새 Ubuntu 워크스테이션을 빠르게 세팅하기 위한 스크립트 모음입니다.

> [!CAUTION]
> 현재 설치는 Ubuntu Server 기준입니다. Ubuntu Desktop에서 GNOME을 계속 사용하려면 Xfce Desktop 설치와 `.desktop` 바로가기 복사 단계를 건너뛰세요.

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

- `01_install_base.sh`
  - 기본 패키지를 설치합니다.
  - `install/set-cpu-performance.sh`를 호출해 CPU governor를 performance로 설정합니다.
  - NVIDIA 드라이버를 설치합니다.
  - 설치가 끝나면 재부팅합니다.

- `02_install_dev_stack.sh`
  - VSCode, Chrome, Sunshine을 설치합니다.
  - Sunshine은 Moonlight 클라이언트로 접속하는 자체 호스팅 스트리밍 서버입니다.
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

- `install/`
  - 개별 설치 스크립트가 들어 있습니다.
  - `install_sunshine.sh`는 Cloudsmith 저장소를 등록하고 Sunshine을 설치한 뒤, 사용자를 `input` 그룹에 추가하고 systemd 사용자 서비스(`app-dev.lizardbyte.app.Sunshine`)를 활성화합니다.
    - `~/.config/sunshine/sunshine.conf`에 `capture = x11`을 설정합니다.
    - `sunshine_name`을 `<사용자 이름>_<로컬 IP 마지막 옥텟>`(예: `sybae_215`)으로 설정합니다(기본값은 PC 호스트명). IP를 감지하지 못하면 사용자 이름만 사용합니다.
    - `nvidia-smi`로 NVIDIA 드라이버가 감지되면 `encoder = nvenc`를 설정하고, 감지되지 않으면 기본값(자동 선택)을 유지합니다.
    - 로컬 IP를 감지할 수 있으면 `csrf_allowed_origins = https://<감지된 IP>:47990`을 설정합니다.
    - `~/.local/bin/sunshine-disable-mouse-accel.sh` 훅 스크립트를 배포하고, `global_prep_cmd`에 등록해 매 세션 시작마다 백그라운드로 실행되게 합니다. 이 훅은 Sunshine이 생성하는 가상 마우스 장치(이름에 `sunshine`이 포함된 libinput 장치)를 찾아 `libinput Accel Profile Enabled`를 flat으로, `libinput Accel Speed`를 -1로 설정해 호스트 X11의 pointer acceleration을 꺼줍니다. 가상 장치는 세션마다 새로 생성되므로 접속할 때마다 자동으로 재적용됩니다.
    - `~/.config/sunshine/apps.json`을 Desktop 항목 하나만 남긴 내용으로 덮어씁니다(Low Res Desktop/Steam Big Picture 제거). 재설치·재실행 시 매번 이 상태로 리셋됩니다.
    - `sunshine --creds`로 웹 UI 로그인 아이디/비밀번호를 `<사용자 이름> / 1`로 자동 설정합니다. 비밀번호가 매우 단순하니 필요하면 웹 UI에서 바꾸세요.
    - 설치 후 로그아웃/재로그인이 필요하며, 웹 UI는 `https://<감지된 IP 또는 localhost>:47990`입니다.
    - 클라이언트 PIN 페어링은 스크립트가 자동으로 처리하지 않습니다. 아래 "Sunshine 최초 접속 설정"을 따라 직접 진행하세요.
  - `legacy/`에는 더 이상 기본 실행에 포함되지 않는 XRDP/NoMachine 설치 스크립트(`install_xrdp.sh`, `install_nm.sh`, `nm/nm.deb`)가 들어 있습니다.
  - `install_ros2.sh`는 `jammy -> humble`, `noble -> jazzy`, `resolute -> lyrical`로 자동 분기합니다.
  - `install_isaaclab.sh`는 기본적으로 Isaac Lab `v3.0.0-beta2`를 `~/IsaacLab`에 클론하고, `~/isaacsim`(Isaac Sim 6.0.1 설치 경로)를 `_isaac_sim`으로 심볼릭 링크한 뒤 `./isaaclab.sh --install`을 실행합니다. `ISAACLAB_VERSION`, `ISAACSIM_DIR`, `ISAACLAB_DIR` 환경 변수로 버전과 경로를 바꿀 수 있습니다. `install/install_isaacsim.sh`로 Isaac Sim을 먼저 설치해야 합니다.
  - `copy_files.sh`는 `desktop/` 폴더의 바로가기 파일 중 `htop.desktop`과 `nvidia-smi.desktop`을 `~/.config/autostart`에 복사하고, 나머지는 `~/Desktop`에 복사합니다.
  - 바로가기 복사 후 사용자별 기본 설정과 무관하게 Greybird/elementary-xfce 테마와 단일 하단 패널을 구성합니다.
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

## 실행 순서

Ubuntu 22.04/24.04에서 전체 스택을 설치하는 순서입니다.

1. `01_install_base.sh`를 실행합니다.
2. 재부팅합니다.
3. `02_install_dev_stack.sh`를 실행합니다.
4. 전체 설치가 끝나면 다시 재부팅합니다.
5. (선택) Isaac Lab이 필요하면 `03_install_isaac_lab.sh`를 실행합니다.

## 실행 방법

저장소 루트에서 다음처럼 실행합니다.

```bash
bash 01_install_base.sh
bash 02_install_dev_stack.sh
bash 03_install_isaac_lab.sh
```

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
├── 01_install_base.sh
├── 02_install_dev_stack.sh
├── 03_install_isaac_lab.sh
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
│   ├── install_chrome.sh
│   ├── install_isaaclab.sh
│   ├── install_isaacsim.sh
│   ├── install_nvidia_container_toolkit.sh
│   ├── install_ros2.sh
│   ├── install_sunshine.sh
│   ├── install_vscode.sh
│   ├── set-cpu-performance.sh
│   └── legacy/
│       ├── install_xrdp.sh
│       ├── install_nm.sh
│       └── nm/
│           └── nm.deb
└── README.md
```
