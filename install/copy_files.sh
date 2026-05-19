#!/bin/bash
set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
desktop_src_dir="$(cd "$script_dir/../desktop" && pwd)"
autostart_dir="$HOME/.config/autostart"
desktop_dir="$HOME/Desktop"
current_home="$HOME"

echo "========================================"
echo "바로가기 복사 시작"
echo "========================================"

mkdir -p "$autostart_dir"
mkdir -p "$desktop_dir"

for file in htop.desktop nvidia-smi.desktop; do
    src="$desktop_src_dir/$file"
    dst="$autostart_dir/$file"

    if [ ! -f "$src" ]; then
        echo "파일을 찾을 수 없습니다: $src"
        exit 1
    fi

    cp "$src" "$dst"
    chmod +x "$dst"
done

for file in htop.desktop nvidia-smi.desktop code.desktop google-chrome.desktop xfce4-terminal-emulator.desktop; do
    src="$desktop_src_dir/$file"
    dst="$desktop_dir/$file"

    if [ ! -f "$src" ]; then
        echo "파일을 찾을 수 없습니다: $src"
        exit 1
    fi

    cp "$src" "$dst"
    chmod +x "$dst"
done

sed \
    -e "s|__HOME__|$current_home|g" \
    "$desktop_src_dir/isaac-sim.desktop" > "$desktop_dir/isaac-sim.desktop"
chmod +x "$desktop_dir/isaac-sim.desktop"

echo "========================================"
echo "바로가기 복사 완료"
echo "========================================"
