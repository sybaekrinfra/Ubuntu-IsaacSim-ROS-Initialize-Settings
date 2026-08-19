#!/bin/bash
set -e

ISAACLAB_VERSION="${ISAACLAB_VERSION:-v3.0.0-beta2}"
ISAACSIM_DIR="${ISAACSIM_DIR:-$HOME/isaacsim}"
ISAACLAB_DIR="${ISAACLAB_DIR:-$HOME/IsaacLab}"
ISAACLAB_REPO="https://github.com/isaac-sim/IsaacLab.git"

echo "NVIDIA Isaac Lab ${ISAACLAB_VERSION} installation start"

echo "[1/5] Checking Isaac Sim installation"
if [ ! -d "$ISAACSIM_DIR" ]; then
    echo "Isaac Sim installation not found at $ISAACSIM_DIR"
    echo "Run install/install_isaacsim.sh first (Isaac Sim 6.0.1 is required for Isaac Lab ${ISAACLAB_VERSION})."
    exit 1
fi

echo "[2/5] Cloning Isaac Lab ${ISAACLAB_VERSION}"
if [ -d "$ISAACLAB_DIR/.git" ]; then
    echo "Isaac Lab repository already exists at $ISAACLAB_DIR, fetching tags instead of cloning."
    git -C "$ISAACLAB_DIR" fetch --tags
else
    git clone "$ISAACLAB_REPO" "$ISAACLAB_DIR"
fi
git -C "$ISAACLAB_DIR" checkout "$ISAACLAB_VERSION"

echo "[3/5] Linking Isaac Sim into Isaac Lab"
cd "$ISAACLAB_DIR"
if [ -e "_isaac_sim" ] && [ ! -L "_isaac_sim" ]; then
    echo "$ISAACLAB_DIR/_isaac_sim already exists and is not a symlink. Remove it and re-run."
    exit 1
fi
ln -sfn "$ISAACSIM_DIR" _isaac_sim

echo "[4/5] Granting execute permission"
chmod +x isaaclab.sh

echo "[5/5] Installing Isaac Lab extensions"
./isaaclab.sh --install

echo "Isaac Lab ${ISAACLAB_VERSION} installation complete"
echo "Check commands (run from $ISAACLAB_DIR):"
echo "  ./isaaclab.sh -p scripts/tutorials/00_sim/create_empty.py"
