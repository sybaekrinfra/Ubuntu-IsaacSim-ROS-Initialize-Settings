#!/bin/bash
set -e

select_isaacsim_version() {
    local choice="${1:-}"

    if [ -z "$choice" ]; then
        echo "Select Isaac Sim version to install:"
        echo "  1) 6.0.0 (recommended)"
        echo "  2) 5.0.0"
        echo "  3) 4.5.0"
        read -r -p "Enter choice [1-3, default: 1]: " choice
    fi

    case "$choice" in
        ""|1|6.0.0)
            ISAACSIM_VERSION="6.0.0"
            ISAACSIM_URL="https://downloads.isaacsim.nvidia.com/isaac-sim-standalone-6.0.0-linux-x86_64.zip"
            ;;
        2|5.0.0)
            ISAACSIM_VERSION="5.0.0"
            ISAACSIM_URL="https://download.isaacsim.omniverse.nvidia.com/isaac-sim-standalone-5.0.0-linux-x86_64.zip"
            ;;
        3|4.5.0)
            ISAACSIM_VERSION="4.5.0"
            ISAACSIM_URL="https://download.isaacsim.omniverse.nvidia.com/isaac-sim-standalone-4.5.0-linux-x86_64.zip"
            ;;
        *)
            echo "Invalid selection: $choice"
            exit 1
            ;;
    esac
}

select_isaacsim_version "${ISAACSIM_VERSION:-}"

ZIP_FILE="isaac-sim-standalone-${ISAACSIM_VERSION}-linux-x86_64.zip"

echo "NVIDIA Isaac Sim ${ISAACSIM_VERSION} installation start"
echo "[1/7] Moving to Downloads folder"
cd ~/Downloads

echo "[2/7] Downloading Isaac Sim ${ISAACSIM_VERSION}"
wget -O "$ZIP_FILE" "$ISAACSIM_URL"

echo "[3/7] Creating install folder"
mkdir -p ~/isaacsim

echo "[4/7] Extracting archive"
unzip -o "$ZIP_FILE" -d ~/isaacsim

echo "[5/7] Moving to Isaac Sim folder"
cd ~/isaacsim

echo "[6/7] Granting execute permission"
chmod +x *.sh

echo "[7/7] Running post_install"
./post_install.sh

echo "Isaac Sim ${ISAACSIM_VERSION} installation complete"
