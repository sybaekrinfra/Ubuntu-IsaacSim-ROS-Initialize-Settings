#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "ROS 2 Jazzy 설치 시작"

echo ""
echo "[1/8] 로케일 설정"
sudo apt update
sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

echo ""
echo "[2/8] 필수 패키지 설치"
sudo apt install -y software-properties-common curl gnupg lsb-release python3-pip python3-venv

echo ""
echo "[3/8] Ubuntu universe 저장소 활성화"
sudo add-apt-repository universe -y

echo ""
echo "[4/8] ROS 2 apt source 설치"
sudo apt update
ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
  | grep -F "tag_name" \
  | awk -F'"' '{print $4}')

UBUNTU_CODENAME=$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})

curl -L -o /tmp/ros2-apt-source.deb \
  "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.${UBUNTU_CODENAME}_all.deb"

sudo dpkg -i /tmp/ros2-apt-source.deb

echo ""
echo "[5/8] ROS 개발 도구 설치"
sudo apt update
sudo apt install -y ros-dev-tools
sudo apt install -y python3-colcon-common-extensions

echo ""
echo "[6/8] ROS 2 Jazzy Desktop 설치"
sudo apt update
sudo apt upgrade -y
sudo apt install -y ros-jazzy-desktop

echo ""
echo "[7/8] rosdep 초기화 및 업데이트"
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
else
    echo "rosdep은 이미 초기화되어 있습니다."
fi
rosdep update

echo ""
echo "[8/8] bashrc에 ROS 환경 설정 추가"
if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
fi

if ! grep -q "export ROS_DOMAIN_ID" ~/.bashrc; then
    echo "export ROS_DOMAIN_ID=0" >> ~/.bashrc
fi

source /opt/ros/jazzy/setup.bash

banner "ROS 2 Jazzy 설치 완료"

echo ""
echo "확인 명령어:"
echo "  ros2 --version"
echo "  ros2 run demo_nodes_cpp talker"
echo "  ros2 run demo_nodes_py listener"
