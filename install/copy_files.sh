#!/bin/bash
set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
desktop_src_dir="$(cd "$script_dir/../desktop" && pwd)"
autostart_dir="$HOME/.config/autostart"
desktop_dir="$HOME/Desktop"
current_home="$HOME"
local_bin_dir="$HOME/.local/bin"

echo "바로가기 복사 시작"

mkdir -p "$autostart_dir"
mkdir -p "$desktop_dir"

copy_with_exec() {
    local src="$1"
    local dst="$2"

    install -m 755 "$src" "$dst"
}

for file in htop.desktop nvidia-smi.desktop; do
    src="$desktop_src_dir/$file"
    dst="$autostart_dir/$file"

    if [ ! -f "$src" ]; then
        echo "파일을 찾을 수 없습니다: $src"
        exit 1
    fi

    copy_with_exec "$src" "$dst"
done

for file in htop.desktop nvidia-smi.desktop code.desktop google-chrome.desktop xfce4-terminal-emulator.desktop; do
    src="$desktop_src_dir/$file"
    dst="$desktop_dir/$file"

    if [ ! -f "$src" ]; then
        echo "파일을 찾을 수 없습니다: $src"
        exit 1
    fi

    copy_with_exec "$src" "$dst"
done

for file in isaac-sim.desktop isaac-sim-newton.desktop; do
    src="$desktop_src_dir/$file"
    dst="$desktop_dir/$file"

    if [ ! -f "$src" ]; then
        echo "파일을 찾을 수 없습니다: $src"
        exit 1
    fi

    tmp_isaac_desktop="$(mktemp)"
    sed \
        -e "s|__HOME__|$current_home|g" \
        "$src" > "$tmp_isaac_desktop"
    install -m 755 "$tmp_isaac_desktop" "$dst"
    rm -f "$tmp_isaac_desktop"
done

echo "바로가기 복사 완료"

echo "Xfce 패널 설정 예약"
mkdir -p "$local_bin_dir"
panel_script_src="$script_dir/configure_xfce_panel.sh"
panel_script_dst="$local_bin_dir/configure-xfce-panel.sh"
install -m 755 "$panel_script_src" "$panel_script_dst"

cat > "$autostart_dir/configure-xfce-panel.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Configure Xfce Panel
Exec=$panel_script_dst
OnlyShowIn=XFCE;
X-GNOME-Autostart-enabled=true
Terminal=false
EOF

if [ -n "${DISPLAY:-}" ] && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    "$panel_script_dst" || true
else
    echo "다음 Xfce 로그인 시 패널 설정이 자동 적용됩니다."
fi
