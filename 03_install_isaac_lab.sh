#!/bin/bash
set -e

ISAACLAB_DIR="${ISAACLAB_DIR:-$HOME/IsaacLab}"

echo "Isaac Lab install start"
echo "[1/3] Checking NVIDIA driver"
nvidia-smi

echo "[2/3] Installing Isaac Lab"
bash install/install_isaaclab.sh

echo "[3/3] Running create_empty.py smoke test (headless, 30s timeout)"
cd "$ISAACLAB_DIR"
set +e
timeout 30 ./isaaclab.sh -p scripts/tutorials/00_sim/create_empty.py --headless
status=$?
set -e
# create_empty.py loops forever (while simulation_app.is_running()), so a
# timeout-triggered kill (124) is the expected way this smoke test ends.
if [ "$status" -ne 0 ] && [ "$status" -ne 124 ]; then
    echo "create_empty.py smoke test failed (exit code $status)"
    exit "$status"
fi

echo "Isaac Lab install complete."
