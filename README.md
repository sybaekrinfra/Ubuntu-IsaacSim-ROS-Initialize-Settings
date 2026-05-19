# Ubuntu Setting 스크립트

이 저장소는 새 Ubuntu 워크스테이션을 빠르게 세팅하기 위한 스크립트 모음입니다.

## 구성

- `01_install_base.sh`
  - 기본 패키지를 설치합니다.
  - NVIDIA 드라이버를 설치합니다.
  - 설치가 끝나면 재부팅합니다.

- `02_install_dev_stack.sh`
  - VSCode, Chrome, NoMachine을 설치합니다.
  - Docker를 설치합니다.
  - ROS 2 Jazzy를 설치합니다.
  - NVIDIA Container Toolkit을 설치합니다.
  - Isaac Sim을 설치합니다.
  - 바탕화면과 자동실행 바로가기를 복사합니다.

- `install/`
  - 개별 설치 스크립트가 들어 있습니다.
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

## 참고

- `02_install_dev_stack.sh`는 자동 재개 방식이 아닙니다. 첫 번째 재부팅 후 직접 다시 실행해야 합니다.
- `install/copy_files.sh`는 다음처럼 복사합니다.
  - `htop.desktop` -> `~/.config/autostart`
  - `nvidia-smi.desktop` -> `~/.config/autostart`
  - `code.desktop` -> `~/Desktop`
  - `google-chrome.desktop` -> `~/Desktop`
  - `xfce4-terminal-emulator.desktop` -> `~/Desktop`
  - `isaac-sim.desktop` -> `~/Desktop`
- `install/install_ros2_jazzy.sh`에는 `rosdep init/update`와 기본 Python 개발 패키지가 포함되어 있습니다.
  - `python3-pip`
  - `python3-venv`
  - `python3-colcon-common-extensions`
- Docker 관련 단계는 호스트 시스템용입니다. 이미 별도의 Docker 이미지가 있다면 그 이미지를 계속 사용하셔도 됩니다.

## 주의사항

- 네트워크 연결이 필요합니다.
- 일부 단계는 `sudo` 권한이 필요합니다.
- `nvidia-driver-580`은 저장소 상태에 따라 설치 가능 여부가 달라질 수 있습니다.
- ROS 2 설치는 GitHub 최신 릴리스 API에 의존합니다.

## 디렉터리 예시

```text
Ubuntu Setting/
├── 01_install_base.sh
├── 02_install_dev_stack.sh
├── desktop/
│   ├── CPU-USAGE.desktop
│   ├── IsaacSim.desktop
│   ├── NVIDIA-SMI.desktop
│   ├── code.desktop
│   ├── google-chrome.desktop
│   ├── htop.desktop
│   ├── nvidia-smi.desktop
│   └── xfce4-terminal-emulator.desktop
├── install/
│   ├── copy_files.sh
│   ├── install_chrome.sh
│   ├── install_isaacsim.sh
│   ├── install_nomachine.sh
│   ├── install_nvidia_container_toolkit.sh
│   ├── install_ros2_jazzy.sh
│   └── install_vscode.sh
└── README.md
```
