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
  - VSCode, Chrome, XRDP를 설치합니다.
  - XRDP는 Windows RDP 클라이언트에서 전달한 계정으로 Xorg 세션을 바로 시작하도록 설정합니다.
  - Xfce의 기본 Terminal Emulator를 Xfce Terminal로 설정합니다.
  - Docker를 설치합니다.
  - `install/install_ros2.sh`를 호출해 Ubuntu 버전에 맞는 ROS 2를 설치합니다.
  - NVIDIA Container Toolkit을 설치합니다.
  - Isaac Sim을 설치합니다.
  - 바탕화면과 자동실행 바로가기를 복사합니다.

- `install/`
  - 개별 설치 스크립트가 들어 있습니다.
  - `install_ros2.sh`는 `jammy -> humble`, `noble -> jazzy`, `resolute -> lyrical`로 자동 분기합니다.
  - `copy_files.sh`는 `desktop/` 폴더의 바로가기 파일 중 `htop.desktop`과 `nvidia-smi.desktop`을 `~/.config/autostart`에 복사하고, 나머지는 `~/Desktop`에 복사합니다.
  - 바로가기 복사 후 Xfce 패널을 화면 하단으로 옮기고, 확장형 구분자 뒤에 모든 `.desktop` 바로가기를 우측 아이콘으로 등록합니다. Xfce 세션이 실행 중이 아니면 다음 로그인 때 자동 적용됩니다.

- `desktop/`
  - `.desktop` 바로가기 파일이 들어 있습니다.

## 실행 순서

Ubuntu 22.04/24.04에서 전체 스택을 설치하는 순서입니다.

1. `01_install_base.sh`를 실행합니다.
2. 재부팅합니다.
3. `02_install_dev_stack.sh`를 실행합니다.
4. 전체 설치가 끝나면 다시 재부팅합니다.

## 실행 방법

저장소 루트에서 다음처럼 실행합니다.

```bash
bash 01_install_base.sh
bash 02_install_dev_stack.sh
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
│   ├── install_isaacsim.sh
│   ├── install_xrdp.sh
│   ├── install_nvidia_container_toolkit.sh
│   ├── install_ros2.sh
│   ├── install_vscode.sh
│   └── set-cpu-performance.sh
└── README.md
```
