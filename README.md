# Ubuntu Setting 스크립트

이 저장소는 새 Ubuntu 워크스테이션을 빠르게 세팅하기 위한 스크립트 모음입니다.

## 주의점 : 현재 설치는 Ubuntu Server 버전 기준입니다. Desktop 사용자의 경우, GNOME Desktop을 사용한다면, 해당 내용 중 바로가기 파일과 xfce Desktop 설치를 건너뛰세요.

현재 구조는 하나의 공통 스크립트 세트로 통합되어 있고, `Ubuntu` 버전으로 `ROS` 배포판을 자동 선택합니다.

## 지원 조합

- `Ubuntu 24.04` -> `ROS 2 Jazzy`
- `Ubuntu 22.04` -> `ROS 2 Humble`

`ROS_DISTRO` 환경 변수를 직접 지정하면 수동으로도 선택할 수 있습니다.

## 구성

- `01_install_base.sh`
  - 기본 패키지를 설치합니다.
  - `install/set-cpu-performance.sh`를 호출해 CPU governor를 performance로 설정합니다.
  - NVIDIA 드라이버를 설치합니다.
  - 설치가 끝나면 재부팅합니다.

- `02_install_dev_stack.sh`
  - VSCode, Chrome, NoMachine을 설치합니다.
  - Docker를 설치합니다.
  - `install/install_ros2.sh`를 호출해 Ubuntu 버전에 맞는 ROS 2를 설치합니다.
  - NVIDIA Container Toolkit을 설치합니다.
  - Isaac Sim을 설치합니다.
  - 바탕화면과 자동실행 바로가기를 복사합니다.

- `install/`
  - 개별 설치 스크립트가 들어 있습니다.
  - `install_ros2.sh`는 `jammy -> humble`, `noble -> jazzy`로 자동 분기합니다.
  - `copy_files.sh`는 `desktop/` 폴더의 바로가기 파일 중 `htop.desktop`과 `nvidia-smi.desktop`을 `~/.config/autostart`에 복사하고, 나머지는 `~/Desktop`에 복사합니다.

- `desktop/`
  - `.desktop` 바로가기 파일이 들어 있습니다.

## 실행 순서

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
```

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
- `nvidia-driver-580`은 저장소 상태에 따라 설치 가능 여부가 달라질 수 있습니다.
- ROS 2 설치는 GitHub 최신 릴리스 API에 의존합니다.
- Ubuntu 버전과 ROS 배포판 조합은 함께 맞춰야 합니다. 예를 들어 `22.04`에서는 `Humble`, `24.04`에서는 `Jazzy` 기준으로 확인하는 것이 안전합니다.

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
│   ├── NVIDIA-SMI.desktop
│   └── xfce4-terminal-emulator.desktop
├── install/
│   ├── copy_files.sh
│   ├── install_chrome.sh
│   ├── install_isaacsim.sh
│   ├── install_nomachine.sh
│   ├── install_nvidia_container_toolkit.sh
│   ├── install_ros2.sh
│   ├── install_vscode.sh
│   └── set-cpu-performance.sh
└── README.md
```
