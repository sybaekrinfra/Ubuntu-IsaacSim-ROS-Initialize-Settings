#!/bin/bash
set -e

banner() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

current_user="$(id -un)"
current_home="$HOME"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

banner "Desktop shortcut setup start"

echo ""
echo "[1/5] Create autostart directory"
mkdir -p ~/.config/autostart

echo ""
echo "[2/5] Create Desktop directory"
mkdir -p ~/Desktop

echo ""
echo "[3/5] Copy NVIDIA-SMI and CPU-USAGE to autostart"
cp "$script_dir/NVIDIA-SMI.desktop" ~/.config/autostart/
cp "$script_dir/CPU-USAGE.desktop" ~/.config/autostart/

echo ""
echo "[4/5] Copy desktop launchers"
cp "$script_dir/NVIDIA-SMI.desktop" ~/Desktop/
cp "$script_dir/CPU-USAGE.desktop" ~/Desktop/
sed \
    -e "s|__HOME__|$current_home|g" \
    -e "s|__USER__|$current_user|g" \
    "$script_dir/IsaacSim.desktop" > ~/Desktop/IsaacSim.desktop

echo ""
echo "[5/5] Make launchers executable"
chmod +x ~/.config/autostart/NVIDIA-SMI.desktop
chmod +x ~/.config/autostart/CPU-USAGE.desktop
chmod +x ~/Desktop/NVIDIA-SMI.desktop
chmod +x ~/Desktop/CPU-USAGE.desktop
chmod +x ~/Desktop/IsaacSim.desktop

banner "Desktop shortcut setup complete"
