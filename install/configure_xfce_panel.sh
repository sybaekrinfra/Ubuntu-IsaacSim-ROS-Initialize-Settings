#!/bin/bash
set -e

desktop_dir="$HOME/Desktop"
panel_config_dir="$HOME/.config/xfce4/panel"
marker_file="$panel_config_dir/.desktop-launchers-configured"
autostart_file="$HOME/.config/autostart/configure-xfce-panel.desktop"

if [ -f "$marker_file" ]; then
    rm -f "$autostart_file"
    exit 0
fi

if ! command -v xfconf-query >/dev/null 2>&1 || ! pgrep -x xfce4-panel >/dev/null 2>&1; then
    echo "Xfce panel session is not running; configuration will be retried at login."
    exit 1
fi

panel_id="$(
    xfconf-query -c xfce4-panel -p /panels 2>/dev/null \
        | sed -n 's/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]*$/\1/p' \
        | head -n 1
)"
panel_id="${panel_id:-1}"
panel_path="/panels/panel-${panel_id}"

set_property() {
    local property="$1"
    local type="$2"
    local value="$3"

    if xfconf-query -c xfce4-panel -p "$property" >/dev/null 2>&1; then
        xfconf-query -c xfce4-panel -p "$property" -s "$value"
    else
        xfconf-query -c xfce4-panel -p "$property" -n -t "$type" -s "$value"
    fi
}

echo "Moving Xfce panel ${panel_id} to the bottom"
set_property "$panel_path/position-locked" bool false
set_property "$panel_path/mode" int 0
set_property "$panel_path/length" int 100
set_property "$panel_path/position" string 'p=6;x=0;y=0'
set_property "$panel_path/position-locked" bool true

plugin_ids() {
    xfconf-query -c xfce4-panel -p "$panel_path/plugin-ids" 2>/dev/null \
        | sed -n 's/^[[:space:]]*\([0-9][0-9]*\)[[:space:]]*$/\1/p'
}

new_plugin_id() {
    local before="$1"
    local after
    after="$(plugin_ids)"
    comm -13 \
        <(printf '%s\n' "$before" | sed '/^$/d' | sort -n) \
        <(printf '%s\n' "$after" | sed '/^$/d' | sort -n) \
        | tail -n 1
}

echo "Adding an expandable separator for right-aligned launchers"
before_ids="$(plugin_ids)"
xfce4-panel --add=separator
sleep 1
separator_id="$(new_plugin_id "$before_ids")"
if [ -z "$separator_id" ]; then
    echo "Could not determine the new separator plugin ID." >&2
    exit 1
fi
set_property "/plugins/plugin-${separator_id}/expand" bool true
set_property "/plugins/plugin-${separator_id}/style" int 0

launchers=(
    xfce4-terminal-emulator.desktop
    google-chrome.desktop
    code.desktop
    htop.desktop
    nvidia-smi.desktop
    isaac-sim.desktop
    isaac-sim-newton.desktop
)

for desktop_file in "${launchers[@]}"; do
    source_file="$desktop_dir/$desktop_file"
    if [ ! -f "$source_file" ]; then
        echo "Launcher file not found: $source_file" >&2
        exit 1
    fi

    before_ids="$(plugin_ids)"
    xfce4-panel --add=launcher
    sleep 1
    launcher_id="$(new_plugin_id "$before_ids")"
    if [ -z "$launcher_id" ]; then
        echo "Could not determine launcher plugin ID for $desktop_file." >&2
        exit 1
    fi

    launcher_dir="$panel_config_dir/launcher-${launcher_id}"
    mkdir -p "$launcher_dir"
    install -m 644 "$source_file" "$launcher_dir/$desktop_file"
    items_property="/plugins/plugin-${launcher_id}/items"
    if xfconf-query -c xfce4-panel -p "$items_property" >/dev/null 2>&1; then
        xfconf-query -c xfce4-panel -p "$items_property" -a -t string -s "$desktop_file"
    else
        xfconf-query -c xfce4-panel -p "$items_property" -n -a -t string -s "$desktop_file"
    fi
done

mkdir -p "$panel_config_dir"
touch "$marker_file"
rm -f "$autostart_file"
xfce4-panel --restart
echo "Xfce panel configuration complete"
