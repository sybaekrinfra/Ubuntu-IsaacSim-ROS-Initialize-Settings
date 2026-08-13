#!/bin/bash
set -e

desktop_dir="$HOME/Desktop"
panel_config_dir="$HOME/.config/xfce4/panel"
marker_file="$panel_config_dir/.desktop-launchers-configured-v3"
old_marker_file="$panel_config_dir/.desktop-launchers-configured"
v2_marker_file="$panel_config_dir/.desktop-launchers-configured-v2"
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

screen_size="$(xrandr --current 2>/dev/null | awk '$0 ~ /\*/ { print $1; exit }')"
screen_width="${screen_size%x*}"
screen_height="${screen_size#*x}"
if ! [[ "$screen_width" =~ ^[0-9]+$ && "$screen_height" =~ ^[0-9]+$ ]]; then
    screen_width=1920
    screen_height=1080
fi
panel_x=$((screen_width / 2))
panel_y=$((screen_height - 1))

echo "Moving Xfce panel ${panel_id} to the bottom (${panel_x}, ${panel_y})"
set_property "$panel_path/position-locked" bool false
set_property "$panel_path/mode" int 0
set_property "$panel_path/length" int 100
set_property "$panel_path/position" string "p=6;x=${panel_x};y=${panel_y}"
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

plugin_name() {
    xfconf-query -c xfce4-panel -p "/plugins/plugin-$1" 2>/dev/null || true
}

launcher_id_for_file() {
    local desktop_file="$1"
    local id
    local item

    while read -r id; do
        [ -n "$id" ] || continue
        [ "$(plugin_name "$id")" = "launcher" ] || continue
        while read -r item; do
            if [ "$item" = "$desktop_file" ]; then
                echo "$id"
                return 0
            fi
        done < <(
            xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}/items" 2>/dev/null \
                | sed -n 's/^[[:space:]]*\([^[:space:]][^[:space:]]*\.desktop\)[[:space:]]*$/\1/p'
        )
    done < <(plugin_ids)
    return 1
}

launchers=(
    xfce4-terminal-emulator.desktop
    google-chrome.desktop
    code.desktop
    isaac-sim.desktop
)
managed_ids=()

for desktop_file in "${launchers[@]}"; do
    source_file="$desktop_dir/$desktop_file"
    if [ ! -f "$source_file" ]; then
        echo "Launcher file not found: $source_file" >&2
        exit 1
    fi

    launcher_id="$(launcher_id_for_file "$desktop_file" || true)"
    if [ -z "$launcher_id" ]; then
        before_ids="$(plugin_ids)"
        xfce4-panel --add=launcher
        sleep 1
        launcher_id="$(new_plugin_id "$before_ids")"
    fi
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
    managed_ids+=("$launcher_id")
done

removed_launchers=(
    htop.desktop
    nvidia-smi.desktop
    isaac-sim-newton.desktop
)
removed_ids=()
for desktop_file in "${removed_launchers[@]}"; do
    launcher_id="$(launcher_id_for_file "$desktop_file" || true)"
    [ -n "$launcher_id" ] && removed_ids+=("$launcher_id")
done

all_ids=()
while read -r id; do
    [ -n "$id" ] && all_ids+=("$id")
done < <(plugin_ids)

# Version 1 placed an expandable separator immediately before all managed
# launchers at the end. Remove that separator from the panel order when found.
obsolete_separator=""
if [ -f "$old_marker_file" ] || [ -f "$v2_marker_file" ]; then
    first_managed="${managed_ids[0]}"
    for index in "${!all_ids[@]}"; do
        if [ "${all_ids[$index]}" = "$first_managed" ] && [ "$index" -gt 0 ]; then
            candidate="${all_ids[$((index - 1))]}"
            if [ "$(plugin_name "$candidate")" = "separator" ]; then
                obsolete_separator="$candidate"
            fi
            break
        fi
    done
fi

base_ids=()
for id in "${all_ids[@]}"; do
    skip=false
    [ "$id" = "$obsolete_separator" ] && skip=true
    for managed_id in "${managed_ids[@]}"; do
        [ "$id" = "$managed_id" ] && skip=true
    done
    for removed_id in "${removed_ids[@]}"; do
        [ "$id" = "$removed_id" ] && skip=true
    done
    [ "$skip" = false ] && base_ids+=("$id")
done

# Insert shortcuts before the notification/network/battery/sound/clock group.
anchor_index="${#base_ids[@]}"
for index in "${!base_ids[@]}"; do
    name="$(plugin_name "${base_ids[$index]}")"
    case "$name" in
        *statusnotifier*|*systray*|*notification*|*indicator*|*network*|*power*|*battery*|*pulseaudio*|*volume*|*clock*|*datetime*|*xkb*)
            anchor_index="$index"
            break
            ;;
    esac
done

ordered_ids=(
    "${base_ids[@]:0:$anchor_index}"
    "${managed_ids[@]}"
    "${base_ids[@]:$anchor_index}"
)

plugin_ids_property="$panel_path/plugin-ids"
xfconf_args=(-c xfce4-panel -p "$plugin_ids_property" -a)
for id in "${ordered_ids[@]}"; do
    xfconf_args+=(-t int -s "$id")
done
xfconf-query "${xfconf_args[@]}"

if [ -n "$obsolete_separator" ]; then
    xfconf-query -c xfce4-panel -p "/plugins/plugin-${obsolete_separator}" -r -R || true
fi
for removed_id in "${removed_ids[@]}"; do
    xfconf-query -c xfce4-panel -p "/plugins/plugin-${removed_id}" -r -R || true
done

mkdir -p "$panel_config_dir"
touch "$marker_file"
rm -f "$old_marker_file" "$v2_marker_file" "$autostart_file"
xfce4-panel --restart
echo "Xfce panel configuration complete"
