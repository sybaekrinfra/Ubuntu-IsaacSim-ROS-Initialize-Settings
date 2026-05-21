#!/bin/bash
set -e

detect_ros_distro() {
    if [ -n "${ROS_DISTRO:-}" ]; then
        echo "$ROS_DISTRO"
        return
    fi

    UBUNTU_CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}")

    case "$UBUNTU_CODENAME" in
        jammy)
            echo "humble"
            ;;
        noble)
            echo "jazzy"
            ;;
        *)
            echo ""
            ;;
    esac
}

ROS_DISTRO="$(detect_ros_distro)"

if [ -z "$ROS_DISTRO" ]; then
    echo "Unsupported Ubuntu version. Set ROS_DISTRO manually or run on jammy/noble."
    exit 1
fi

if [ "$ROS_DISTRO" != "humble" ] && [ "$ROS_DISTRO" != "jazzy" ]; then
    echo "Unsupported ROS_DISTRO: $ROS_DISTRO"
    echo "Supported values: humble, jazzy"
    exit 1
fi

echo "ROS 2 ${ROS_DISTRO} install start"
echo "[1/8] Locale setup"
sudo apt update
sudo apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

echo "[2/8] Installing required packages"
sudo apt install -y software-properties-common curl gnupg lsb-release python3-pip python3-venv

echo "[3/8] Enabling Ubuntu universe repository"
sudo add-apt-repository universe -y

echo "[4/8] Installing ROS 2 apt source"
sudo apt update
ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
  | grep -F "tag_name" \
  | awk -F'"' '{print $4}')

UBUNTU_CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-${VERSION_CODENAME}}")

curl -L -o /tmp/ros2-apt-source.deb \
  "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.${UBUNTU_CODENAME}_all.deb"

sudo dpkg -i /tmp/ros2-apt-source.deb

echo "[5/8] Installing ROS development tools"
sudo apt update
sudo apt install -y ros-dev-tools
sudo apt install -y python3-colcon-common-extensions

echo "[6/8] Installing ROS 2 ${ROS_DISTRO} desktop"
sudo apt update
sudo apt upgrade -y
sudo apt install -y "ros-${ROS_DISTRO}-desktop"

echo "[7/8] Initializing and updating rosdep"
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
else
    echo "rosdep is already initialized."
fi
rosdep update

echo "[8/8] Adding ROS setup to bashrc"
if ! grep -q "source /opt/ros/${ROS_DISTRO}/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc
fi

if ! grep -q "export ROS_DOMAIN_ID" ~/.bashrc; then
    echo "export ROS_DOMAIN_ID=0" >> ~/.bashrc
fi

source "/opt/ros/${ROS_DISTRO}/setup.bash"

echo "ROS 2 ${ROS_DISTRO} install complete"
echo "Check commands:"
echo "  ros2 --version"
echo "  ros2 run demo_nodes_cpp talker"
echo "  ros2 run demo_nodes_py listener"
