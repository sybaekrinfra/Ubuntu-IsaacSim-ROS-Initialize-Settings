#!/bin/bash
set -e

echo "XRDP installation and configuration start"

echo "[1/5] Installing XRDP and Xorg backend"
sudo apt update
sudo apt install -y xrdp xorgxrdp xfce4-terminal

echo "[2/5] Configuring XRDP to use credentials supplied by the RDP client"
sudo python3 - /etc/xrdp/xrdp.ini <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
settings = {
    "require_credentials": "require_credentials=true\n",
    "autorun": "autorun=Xorg\n",
}
globals_start = next(
    (index for index, line in enumerate(lines) if line.strip().lower() == "[globals]"),
    None,
)

if globals_start is None:
    if lines and not lines[-1].endswith(("\n", "\r")):
        lines[-1] += "\n"
    lines.extend(["\n[Globals]\n", *settings.values()])
else:
    globals_end = next(
        (
            index
            for index in range(globals_start + 1, len(lines))
            if re.match(r"^\s*\[[^]]+\]\s*$", lines[index])
        ),
        len(lines),
    )
    found = set()
    for index in range(globals_start + 1, globals_end):
        match = re.match(r"^\s*([^#;][^=\s]*)\s*=", lines[index])
        if match and match.group(1).lower() in settings:
            key = match.group(1).lower()
            lines[index] = settings[key]
            found.add(key)
    lines[globals_end:globals_end] = [
        value for key, value in settings.items() if key not in found
    ]

path.write_text("".join(lines), encoding="utf-8")
PY

echo "[3/5] Configuring Xfce as the XRDP session"
printf '%s\n' 'startxfce4' > "$HOME/.xsession"
chmod 600 "$HOME/.xsession"

echo "[4/5] Setting Xfce Terminal as the default terminal emulator"
mkdir -p "$HOME/.config/xfce4"
helpers_file="$HOME/.config/xfce4/helpers.rc"
if [ -f "$helpers_file" ]; then
    sed -i '/^TerminalEmulator=/d' "$helpers_file"
fi
printf '%s\n' 'TerminalEmulator=xfce4-terminal' >> "$helpers_file"

echo "[5/5] Enabling and restarting XRDP"
if getent group ssl-cert >/dev/null 2>&1; then
    sudo adduser xrdp ssl-cert
fi
sudo systemctl enable xrdp
sudo systemctl restart xrdp
sudo systemctl status xrdp --no-pager

echo "XRDP installation and configuration complete"
