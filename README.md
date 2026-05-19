# Ubuntu Setting Scripts

이 저장소는 Ubuntu 워크스테이션을 새로 설치한 뒤, 개발/실행 환경을 빠르게 구성하기 위한 스크립트 모음입니다.
ubuntu는 Ubuntu 24.04 Server Edition을 설치하면 됩니다.

## 구성

- `01_install_base.sh`
  - 기본 패키지 설치
  - NVIDIA 드라이버 설치
  - 설치 후 재부팅

- `02_install_dev_stack.sh`
  - VSCode, Chrome, NoMachine 설치
  - Docker 설치
  - ROS 2 Jazzy 설치
  - NVIDIA Container Toolkit 설치
  - Isaac Sim 설치
  - Desktop / Autostart 바로가기 생성

- `install/`
  - 각 개별 설치 스크립트

- `copy/`
  - 바탕화면 바로가기용 `.desktop` 파일
  - 바로가기 복사 스크립트

## 실행 순서

1. `01_install_base.sh` 실행
2. 재부팅
3. `02_install_dev_stack.sh` 실행
4. 설치 완료 후 재부팅

## 실행 방법

루트 디렉터리에서 실행하세요.

```bash
bash 01_install_base.sh
bash 02_install_dev_stack.sh
```

## 참고

- `02_install_dev_stack.sh`는 재부팅 후 자동 재개가 아니라, 사용자가 직접 다시 실행하는 방식입니다.
- `copy/copy_desktop.sh`는 현재 사용자 홈 경로를 기준으로 `IsaacSim.desktop`을 생성합니다.
- `IsaacSim`은 `copy/IsaacSim.desktop` 템플릿을 사용하며, 실제 경로는 실행 시 치환됩니다.
- Docker 관련 부분은 호스트 설치용이며, 별도 Docker image가 있다면 그 이미지를 함께 사용하는 구조입니다.
- `install/install_ros2_jazzy.sh`는 `rosdep init/update`와 Python 개발용 기본 패키지(`python3-pip`, `python3-venv`, `python3-colcon-common-extensions`)까지 포함합니다.

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
├── install/
│   ├── install_chrome.sh
│   ├── install_isaacsim.sh
│   ├── install_nomachine.sh
│   ├── install_nvidia_container_toolkit.sh
│   ├── install_ros2_jazzy.sh
│   └── install_vscode.sh
└── copy/
    ├── CPU-USAGE.desktop
    ├── IsaacSim.desktop
    ├── NVIDIA-SMI.desktop
    └── copy_desktop.sh
```
