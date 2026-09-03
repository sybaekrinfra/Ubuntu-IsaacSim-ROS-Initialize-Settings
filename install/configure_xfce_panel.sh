#!/bin/bash
set -e

desktop_dir="$HOME/Desktop"
panel_config_dir="$HOME/.config/xfce4/panel"
xfce_config_dir="$HOME/.config/xfce4"
marker_file="$panel_config_dir/.xubuntu-layout-v5"
autostart_file="$HOME/.config/autostart/configure-xfce-panel.desktop"

if [ -f "$marker_file" ]; then
    rm -f "$autostart_file"
    exit 0
fi

if ! command -v xfconf-query >/dev/null 2>&1 || [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    echo "Xfce session is not running; configuration will be retried at login."
    exit 1
fi

launchers=(
    xfce4-terminal-emulator.desktop
    google-chrome.desktop
    code.desktop
    isaac-sim.desktop
)
for desktop_file in "${launchers[@]}"; do
    if [ ! -f "$desktop_dir/$desktop_file" ]; then
        echo "Launcher file not found: $desktop_dir/$desktop_file" >&2
        exit 1
    fi
done

set_property() {
    local channel="$1"
    local property="$2"
    local type="$3"
    local value="$4"

    if xfconf-query -c "$channel" -p "$property" >/dev/null 2>&1; then
        xfconf-query -c "$channel" -p "$property" -s "$value"
    else
        xfconf-query -c "$channel" -p "$property" -n -t "$type" -s "$value"
    fi
}

echo "Applying consistent Xubuntu appearance"
if [ -d /usr/share/themes/Greybird ]; then
    set_property xsettings /Net/ThemeName string Greybird
    set_property xfwm4 /general/theme string Greybird
fi

icon_theme=""
for candidate in elementary-xfce-darker elementary-xfce-dark elementary-xfce; do
    if [ -d "/usr/share/icons/$candidate" ]; then
        icon_theme="$candidate"
        break
    fi
done
if [ -n "$icon_theme" ]; then
    set_property xsettings /Net/IconThemeName string "$icon_theme"
fi
set_property xsettings /Gtk/FontName string "Noto Sans 9"
set_property xfwm4 /general/title_font string "Noto Sans Bold 9"

mkdir -p "$xfce_config_dir" "$panel_config_dir"
backup_dir="$xfce_config_dir/panel-backup-before-layout-v5"
if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
    cp -a "$panel_config_dir/." "$backup_dir/" 2>/dev/null || true
    xfconf-query -c xfce4-panel -lv > "$backup_dir/xfce4-panel.txt" 2>/dev/null || true
fi

echo "Creating one full-width bottom panel"
xfce4-panel --quit >/dev/null 2>&1 || true
sleep 2
xfconf-query -c xfce4-panel -p /panels -r -R 2>/dev/null || true
xfconf-query -c xfce4-panel -p /plugins -r -R 2>/dev/null || true

screen_size="$(xrandr --current 2>/dev/null | awk '$0 ~ /\*/ { print $1; exit }')"
screen_width="${screen_size%x*}"
if ! [[ "$screen_width" =~ ^[0-9]+$ ]]; then
    screen_width=1920
fi
panel_x=$((screen_width / 2))

set_property xfce4-panel /configver int 2
xfconf-query -c xfce4-panel -p /panels -n -a -t int -s 1
set_property xfce4-panel /panels/panel-1/mode int 0
set_property xfce4-panel /panels/panel-1/position string "p=12;x=${panel_x};y=0"
set_property xfce4-panel /panels/panel-1/position-locked bool true
set_property xfce4-panel /panels/panel-1/length int 100
set_property xfce4-panel /panels/panel-1/length-adjust bool true
set_property xfce4-panel /panels/panel-1/size int 30
set_property xfce4-panel /panels/panel-1/nrows int 1
set_property xfce4-panel /panels/panel-1/autohide-behavior int 0
set_property xfce4-panel /panels/panel-1/span-monitors bool false

# Xubuntu order with four launchers inserted before the system status area.
plugin_ids=(101 102 103 104 105 106 107 108 109 110 111 112 113)
xfconf_args=(-c xfce4-panel -p /panels/panel-1/plugin-ids -n -a)
for id in "${plugin_ids[@]}"; do
    xfconf_args+=(-t int -s "$id")
done
xfconf-query "${xfconf_args[@]}"

set_property xfce4-panel /plugins/plugin-101 string whiskermenu
set_property xfce4-panel /plugins/plugin-102 string separator
set_property xfce4-panel /plugins/plugin-103 string tasklist
set_property xfce4-panel /plugins/plugin-104 string separator
set_property xfce4-panel /plugins/plugin-105 string launcher
set_property xfce4-panel /plugins/plugin-106 string launcher
set_property xfce4-panel /plugins/plugin-107 string launcher
set_property xfce4-panel /plugins/plugin-108 string launcher
set_property xfce4-panel /plugins/plugin-109 string systray
set_property xfce4-panel /plugins/plugin-110 string notification-plugin
set_property xfce4-panel /plugins/plugin-111 string power-manager-plugin
set_property xfce4-panel /plugins/plugin-112 string pulseaudio
set_property xfce4-panel /plugins/plugin-113 string clock

set_property xfce4-panel /plugins/plugin-102/expand bool false
set_property xfce4-panel /plugins/plugin-102/style int 0
set_property xfce4-panel /plugins/plugin-103/flat-buttons bool true
set_property xfce4-panel /plugins/plugin-103/show-handle bool false
set_property xfce4-panel /plugins/plugin-104/expand bool true
set_property xfce4-panel /plugins/plugin-104/style int 0
set_property xfce4-panel /plugins/plugin-109/menu-is-primary bool true
set_property xfce4-panel /plugins/plugin-109/show-frame bool false
set_property xfce4-panel /plugins/plugin-109/square-icons bool true
set_property xfce4-panel /plugins/plugin-112/enable-keyboard-shortcuts bool true
set_property xfce4-panel /plugins/plugin-113/digital-format string " %d %b, %H:%M "

launcher_ids=(105 106 107 108)
for index in "${!launchers[@]}"; do
    desktop_file="${launchers[$index]}"
    launcher_id="${launcher_ids[$index]}"
    launcher_dir="$panel_config_dir/launcher-${launcher_id}"
    mkdir -p "$launcher_dir"
    install -m 644 "$desktop_dir/$desktop_file" "$launcher_dir/$desktop_file"
    xfconf-query \
        -c xfce4-panel \
        -p "/plugins/plugin-${launcher_id}/items" \
        -n -a -t string -s "$desktop_file"
done

touch "$marker_file"
rm -f \
    "$panel_config_dir/.desktop-launchers-configured" \
    "$panel_config_dir/.desktop-launchers-configured-v2" \
    "$panel_config_dir/.desktop-launchers-configured-v3" \
    "$panel_config_dir/.desktop-launchers-configured-v4" \
    "$autostart_file"

nohup xfce4-panel >/dev/null 2>&1 &
echo "Xubuntu-style panel and appearance configuration complete"
