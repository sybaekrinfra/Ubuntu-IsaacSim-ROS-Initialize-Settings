#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

banner "ROS 2 Jazzy install start"

echo ""
echo "[1/8] Configure locale"
sudo apt update
sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

echo ""
echo "[2/8] Install prerequisites"
sudo apt install -y software-properties-common curl gnupg lsb-release python3-pip python3-venv python3-colcon-common-extensions

echo ""
echo "[3/8] Enable Ubuntu universe repository"
sudo add-apt-repository universe -y

echo ""
echo "[4/8] Install ROS 2 apt source"
sudo apt update
ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
  | grep -F "tag_name" \
  | awk -F'"' '{print $4}')

UBUNTU_CODENAME=$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})

curl -L -o /tmp/ros2-apt-source.deb \
  "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.${UBUNTU_CODENAME}_all.deb"

sudo dpkg -i /tmp/ros2-apt-source.deb

echo ""
echo "[5/8] Install ROS development tools"
sudo apt update
sudo apt install -y ros-dev-tools

echo ""
echo "[6/8] Install ROS 2 Jazzy Desktop"
sudo apt update
sudo apt upgrade -y
sudo apt install -y ros-jazzy-desktop

echo ""
echo "[7/8] Initialize and update rosdep"
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
else
    echo "rosdep already initialized"
fi
rosdep update

echo ""
echo "[8/8] Add ROS environment setup to bashrc"
if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
fi

source /opt/ros/jazzy/setup.bash

banner "ROS 2 Jazzy install complete"

echo ""
echo "Verification commands:"
echo "  ros2 --version"
echo "  ros2 run demo_nodes_cpp talker"
echo "  ros2 run demo_nodes_py listener"
