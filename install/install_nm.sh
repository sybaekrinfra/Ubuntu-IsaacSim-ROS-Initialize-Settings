#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEB_PATH="${SCRIPT_DIR}/../nm/nm.deb"

if [ ! -f "${DEB_PATH}" ]; then
    echo "NoMachine package not found: ${DEB_PATH}" >&2
    exit 1
fi

sudo apt install -y "${DEB_PATH}"
